// Inference only: Quran Lab's SDK does not judge or correct the recitation.
import { TajweedClient } from '@quran-lab/tajweedformer';

let client;
let model;
let session;
let initializing = false;

function requireModel() {
  if (!model) throw new Error('TajweedFormer has not been initialized');
  return model;
}

function encodeHeads(heads) {
  const result = {};
  for (const name of heads.names) {
    const head = heads.get(name);
    result[name] = {frames: head.frames, classes: head.classes, frameMs: head.frameMs,
      values: Array.from(head.values, value => {
        if (Number.isFinite(value)) return value;
        if (value === -Infinity) return '-Infinity';
        throw new Error('Non-finite value in V4 model output');
      })};
  }
  return result;
}

async function runSource(from, sampleRate) {
  if (session) throw new Error('A TajweedFormer session is already open');
  const options = {from, pace: 'fast'};
  if (sampleRate !== undefined) options.sampleRate = sampleRate;
  const current = await requireModel().listen(options);
  session = current;
  let final = null;
  try {
    for await (const chunk of current.chunks) {
      if (chunk.decoded.isFinal) final = {text: chunk.decoded.text, tokens: chunk.decoded.tokens};
    }
    const heads = await current.finish();
    if (!final) throw new Error('No final output from the audio');
    return JSON.stringify({...final, heads: encodeHeads(heads)});
  } catch (error) {
    await current.cancel().catch(() => {});
    throw error;
  } finally { if (session === current) session = null; }
}

globalThis.quranLibraryTajweedFormer = {
  async initialize(key) {
    if (!key || typeof key !== 'string') throw new Error('A web key is required');
    if (client || initializing) throw new Error('TajweedFormer is already initialized');
    initializing = true;
    let next;
    try {
      next = await TajweedClient.create({ key });
      const loaded = await next.model();
      client = next;
      model = loaded;
      return JSON.stringify({version: loaded.version, build: loaded.build,
        blank: loaded.tokens.blank, wordBar: loaded.tokens.wordBar,
        tokens: Array.from({length: loaded.tokens.count}, (_, id) => loaded.tokens.name(id)),
        defaultContext: loaded.defaultContext});
    } catch (error) {
      if (next) await next.close();
      throw error;
    } finally { initializing = false; }
  },
  calibration() {
    const value = requireModel().calibration;
    if (!value) throw new Error('This model has no calibration data');
    return JSON.stringify({sha256: value.sha256, data: value.json});
  },
  async diagnose() {
    requireModel();
    return JSON.stringify(await client.diagnose());
  },
  async reference(surah, ayah) {
    const ref = requireModel().reference;
    if (!ref) throw new Error('This model has no reference data');
    await ref.fetch();
    return JSON.stringify(await ref.units(surah, ayah));
  },
  async sample() {
    return runSource(requireModel().sampleClips[0]);
  },
  async recognize(samples) {
    return runSource(samples, 16000);
  },
  start(onChunk) {
    if (session) throw new Error('A TajweedFormer session is already open');
    session = requireModel().session({sampleRate: 16000, onChunk: chunk => {
      onChunk(JSON.stringify({tokens: chunk.decoded.tokens, settled: chunk.decoded.settled,
        isFinal: chunk.decoded.isFinal, speech: chunk.speech}));
    }});
  },
  push(samples) {
    if (!session) throw new Error('No TajweedFormer session is open');
    session.push(samples);
  },
  async finish() {
    if (!session) throw new Error('No TajweedFormer session is open');
    const current = session;
    try {
      const heads = await current.finish();
      return JSON.stringify(encodeHeads(heads));
    } finally { if (session === current) session = null; }
  },
  async cancel() {
    if (!session) return;
    const current = session;
    try { await current.cancel(); }
    finally { if (session === current) session = null; }
  },
  // Downloads the SDK's protected model files ahead of the first initialize.
  // A short-lived client is used and closed; the files stay in the SDK cache.
  async prefetch(key, unmeteredOnly, onProgress) {
    if (!key || typeof key !== 'string') throw new Error('A web key is required');
    if (client || initializing) throw new Error('TajweedFormer is already initialized');
    initializing = true;
    let next;
    try {
      next = await TajweedClient.create({ key });
      await next.prefetch({
        unmeteredOnly: !!unmeteredOnly,
        onProgress: typeof onProgress === 'function' ? onProgress : null,
      });
      return JSON.stringify(true);
    } finally {
      if (next) await next.close().catch(() => {});
      initializing = false;
    }
  },
  async removeModels(key) {
    if (!key || typeof key !== 'string') throw new Error('A web key is required');
    if (client || initializing) throw new Error('TajweedFormer is already initialized');
    initializing = true;
    let next;
    try {
      next = await TajweedClient.create({ key });
      await next.removeModels();
      return JSON.stringify(true);
    } finally {
      if (next) await next.close().catch(() => {});
      initializing = false;
    }
  },
  async close() {
    try {
      if (session) await session.cancel();
    } finally {
      session = null;
      try {
        if (model) await model.close();
      } finally {
        model = null;
        try { if (client) await client.close(); }
        finally { client = null; }
      }
    }
  },
};
