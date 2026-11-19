import * as net from 'node:net';
import { SeverityNumber, logs as logsApi } from '@opentelemetry/api-logs';

const OTLP_ENDPOINT = process.env.OTEL_EXPORTER_OTLP_ENDPOINT ?? 'http://localhost:4317';
const SERVICE_NAME = process.env.OTEL_SERVICE_NAME ?? 'demo-api';
const TENANT_ID = process.env.TENANT_ID;
const PROBE_TIMEOUT_MS = 1000;
const PROBE_RETRIES = 5;
const PROBE_RETRY_DELAY_MS = 2000;

function probeEndpoint(endpoint: string): Promise<boolean> {
  return new Promise(resolve => {
    const url = new URL(endpoint);
    const socket = net.connect({ host: url.hostname, port: Number(url.port) || 4317 });
    socket.setTimeout(PROBE_TIMEOUT_MS);
    socket.once('connect', () => finish(true));
    socket.once('timeout', () => finish(false));
    socket.once('error', () => finish(false));

    function finish(reachable: boolean): void {
      socket.destroy();
      resolve(reachable);
    }
  });
}

const delay = (ms: number) => new Promise(resolve => setTimeout(resolve, ms));

async function collectorIsReachable(): Promise<boolean> {
  for (let attempt = 1; attempt <= PROBE_RETRIES; attempt++) {
    if (await probeEndpoint(OTLP_ENDPOINT)) return true;
    await delay(PROBE_RETRY_DELAY_MS);
  }
  return false;
}

function forwardConsoleToOtel(): void {
  const otelLogger = logsApi.getLogger('console');
  const levels = [
    ['log', SeverityNumber.INFO],
    ['warn', SeverityNumber.WARN],
    ['error', SeverityNumber.ERROR],
  ] as const;

  for (const [method, severityNumber] of levels) {
    const original = console[method].bind(console);
    console[method] = (...args: unknown[]) => {
      original(...args);
      try {
        otelLogger.emit({
          severityNumber,
          severityText: method.toUpperCase(),
          body: args.map(arg => (typeof arg === 'string' ? arg : JSON.stringify(arg))).join(' '),
        });
      } catch {
        // Telemetry must never fail a request.
      }
    };
  }
}

async function startTelemetry(): Promise<void> {
  if (!(await collectorIsReachable())) return;

  const { NodeSDK, metrics: sdkMetrics } = await import('@opentelemetry/sdk-node');
  const { getNodeAutoInstrumentations } = await import('@opentelemetry/auto-instrumentations-node');
  const { OTLPTraceExporter } = await import('@opentelemetry/exporter-trace-otlp-grpc');
  const { OTLPMetricExporter } = await import('@opentelemetry/exporter-metrics-otlp-grpc');
  const { OTLPLogExporter } = await import('@opentelemetry/exporter-logs-otlp-grpc');
  const { BatchLogRecordProcessor, LoggerProvider } = await import('@opentelemetry/sdk-logs');
  const { resourceFromAttributes } = await import('@opentelemetry/resources');

  const resource = resourceFromAttributes({
    'service.name': SERVICE_NAME,
    'service.namespace': 'acme-planner',
    'container.name': process.env.OTEL_CONTAINER_NAME ?? SERVICE_NAME,
    'deployment.environment.name': process.env.OTEL_DEPLOYMENT_ENVIRONMENT ?? 'unknown',
    ...(TENANT_ID ? { 'tenant.id': TENANT_ID, tenant_id: TENANT_ID } : {}),
  });

  const loggerProvider = new LoggerProvider({
    resource,
    processors: [new BatchLogRecordProcessor({ exporter: new OTLPLogExporter() })],
  });
  logsApi.setGlobalLoggerProvider(loggerProvider);

  const sdk = new NodeSDK({
    resource,
    traceExporter: new OTLPTraceExporter(),
    metricReader: new sdkMetrics.PeriodicExportingMetricReader({
      exporter: new OTLPMetricExporter(),
      exportIntervalMillis: 15_000,
    }),
    instrumentations: [getNodeAutoInstrumentations({ '@opentelemetry/instrumentation-fs': { enabled: false } })],
  });
  sdk.start();

  forwardConsoleToOtel();
  process.stdout.write(`[otel] telemetry active for ${SERVICE_NAME} -> ${OTLP_ENDPOINT}\n`);
}

if (process.env.OTEL_SDK_DISABLED !== 'true') {
  startTelemetry().catch(() => undefined);
}
