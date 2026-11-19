// Developer-only probe: runs the SDK's own sample, never the microphone.
import { TajweedClient } from '@quran-lab/tajweedformer';

try {
  const client = await TajweedClient.create({ key: import.meta.env.VITE_QURANLAB_KEY });
  const model = await client.model();
  const session = await model.listen({ from: model.sampleClips[0] });
  let text = '';
  for await (const chunk of session.chunks) {
    if (chunk.decoded.isFinal) text = chunk.decoded.text;
  }
  const diagnosis = await client.diagnose();
  const { key, model: modelStatus, sdk, backend, lastError } = diagnosis;
  window.smokeResult = { ok: Boolean(text), text, diagnosis: { key, model: modelStatus, sdk, backend, lastError } };
} catch (error) {
  window.smokeResult = { ok: false, code: error.code || 'error', message: error.message };
}
document.querySelector('#status').textContent = JSON.stringify(window.smokeResult, null, 2);
