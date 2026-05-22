export class WasmMamoryHandler {
  #memory;
  #uint32Array;
  #uint8Array;
  #offset = 0;

  get memory() {
    return this.#memory;
  }
  get int32() {
    return this.#uint32Array;
  }

  constructor(memory, ...args) {
    this.#memory = memory;
    this.#uint32Array = new Int32Array(this.#memory.buffer);
    this.#uint8Array = new Int8Array(this.#memory.buffer);
    this.set(...args);
  }

  set(...args) {
    this.#offset = 0;
    let currentOffset = 2 + (args.length * 3);

    const header = [
      // args data length
      0,

      // args count
      args.length,

      // args headers
      ...(args
        .map(value => {
          const typeId = this.#getArgTypeId(value);
          const argOffset = currentOffset;
          const length = typeof value === 'string' ? Math.ceil(value.length / 4) : 1;
          currentOffset += length + 1;

          return [
            // arg type
            typeId,
            // arg offset
            argOffset,
            // arg length
            typeId === 3 ? value.length : 1,
          ];
        }).flat()
      ),
    ];
    header.forEach(val => this.#pushValue(val));

    const body = [...args];
    body.forEach(val => {
      switch (typeof val) {
        case 'boolean':
          this.#pushBoolean(val);
          break;
        case 'number':
          this.#pushNumber(val);
          break;
        case 'string':
          this.#pushString(val);
          break;
        default: ;
      }
    });

    this.#uint32Array[0] = this.#offset;
  }

  #getArgTypeId(arg) {
    return typeof arg === 'boolean' ? 1
      : typeof arg === 'number' ? 2
      : typeof arg === 'string' ? 3
      : 0;
  }

  #pushValue(value) {
    this.#uint32Array[this.#offset++] = value;
  }

  #pushBoolean(bool) {
    this.#uint32Array[this.#offset] = !!bool ? 1 : 0;
    this.#offset += 2;
  }

  #pushNumber(num) {
    this.#uint32Array[this.#offset] = num;
    this.#offset += 2;
  }

  #pushString(str) {
    this.#uint8Array.set(new TextEncoder().encode(str), this.#offset * 4);
    this.#offset += Math.ceil(str.length / 4) + 1;
  }

  getValue(typeId, offset, length) {
    if (typeId === 1) {
      return !!this.#uint32Array[offset];
    }

    if (typeId === 3) {
      const slice = this.#uint8Array.slice(offset * 4, offset * 4 + length);
      return new TextDecoder().decode(slice);
    }

    return this.#uint32Array[offset];
  }

  getString(offset, end) {
    const slice = this.#uint8Array.slice(offset, end + 1);
    return new TextDecoder().decode(slice);
  }

  toValues() {
    const args = [];
    const argsLength = this.#uint32Array[0];
    const argCount = this.#uint32Array[1];

    for (let i = 0; i < argCount; ++i) {
      const typeId = this.#uint32Array[2 + (i * 3)];
      const offset = this.#uint32Array[2 + (i * 3) + 1];
      const length = this.#uint32Array[2 + (i * 3) + 2];
      const value = this.getValue(typeId, offset, length);
      args.push(value);
    }

    return args;
  }
}

//console.log(new WasmMamoryHandler(1, 2, '3456', 7, false, '89101112', true).toValues());