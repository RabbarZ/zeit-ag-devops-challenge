// Small ZIP reader/writer for the pack and hand-in tools. Node built-ins only.
import { crc32, deflateRawSync, inflateRawSync } from 'node:zlib';

export function createZip(entries) {
  if (entries.length > 65535) throw new Error('Too many files for this ZIP format.');
  const locals = [];
  const centrals = [];
  let offset = 0;
  for (const { name, data, mtime = new Date() } of entries) {
    const filename = Buffer.from(name, 'utf8');
    const packed = deflateRawSync(data);
    const date = ((Math.max(1980, mtime.getFullYear()) - 1980) << 9) | ((mtime.getMonth() + 1) << 5) | mtime.getDate();
    const time = (mtime.getHours() << 11) | (mtime.getMinutes() << 5) | (mtime.getSeconds() >> 1);
    const crc = crc32(data);
    const local = Buffer.alloc(30);
    local.writeUInt32LE(0x04034b50, 0);
    local.writeUInt16LE(20, 4);
    local.writeUInt16LE(0x0800, 6); // UTF-8 names
    local.writeUInt16LE(8, 8);
    local.writeUInt16LE(time, 10);
    local.writeUInt16LE(date, 12);
    local.writeUInt32LE(crc, 14);
    local.writeUInt32LE(packed.length, 18);
    local.writeUInt32LE(data.length, 22);
    local.writeUInt16LE(filename.length, 26);
    locals.push(local, filename, packed);

    const central = Buffer.alloc(46);
    central.writeUInt32LE(0x02014b50, 0);
    central.writeUInt16LE(20, 4);
    central.writeUInt16LE(20, 6);
    central.writeUInt16LE(0x0800, 8);
    central.writeUInt16LE(8, 10);
    central.writeUInt16LE(time, 12);
    central.writeUInt16LE(date, 14);
    central.writeUInt32LE(crc, 16);
    central.writeUInt32LE(packed.length, 20);
    central.writeUInt32LE(data.length, 24);
    central.writeUInt16LE(filename.length, 28);
    central.writeUInt32LE(offset, 42);
    centrals.push(central, filename);
    offset += local.length + filename.length + packed.length;
  }

  const directory = Buffer.concat(centrals);
  const end = Buffer.alloc(22);
  end.writeUInt32LE(0x06054b50, 0);
  end.writeUInt16LE(entries.length, 8);
  end.writeUInt16LE(entries.length, 10);
  end.writeUInt32LE(directory.length, 12);
  end.writeUInt32LE(offset, 16);
  return Buffer.concat([...locals, directory, end]);
}

export function readZip(zip) {
  const end = zip.lastIndexOf(Buffer.from([0x50, 0x4b, 0x05, 0x06]));
  if (end < 0) throw new Error('ZIP directory not found.');
  const entries = [];
  for (let i = 0, p = zip.readUInt32LE(end + 16); i < zip.readUInt16LE(end + 10); i++) {
    if (zip.readUInt32LE(p) !== 0x02014b50) throw new Error('Invalid ZIP directory.');
    const method = zip.readUInt16LE(p + 10);
    const length = zip.readUInt32LE(p + 20);
    const nameLength = zip.readUInt16LE(p + 28);
    const name = zip.toString('utf8', p + 46, p + 46 + nameLength);
    const local = zip.readUInt32LE(p + 42);
    const start = local + 30 + zip.readUInt16LE(local + 26) + zip.readUInt16LE(local + 28);
    const packed = zip.subarray(start, start + length);
    if (method !== 0 && method !== 8) throw new Error(`Unsupported ZIP compression: ${method}`);
    const data = method === 8 ? inflateRawSync(packed) : packed;
    if (data.length !== zip.readUInt32LE(p + 24) || crc32(data) !== zip.readUInt32LE(p + 16)) {
      throw new Error(`ZIP checksum failed: ${name}`);
    }
    entries.push({ name, data });
    p += 46 + nameLength + zip.readUInt16LE(p + 30) + zip.readUInt16LE(p + 32);
  }
  return entries;
}
