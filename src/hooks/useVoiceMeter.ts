import { useEffect, useState } from 'react';

export function useVoiceMeter(enabled: boolean) {
  const [level, setLevel] = useState(0);
  const [status, setStatus] = useState<'idle' | 'listening' | 'blocked' | 'unsupported'>('idle');

  useEffect(() => {
    const deferState = (callback: () => void) => window.queueMicrotask(callback);

    if (!enabled) {
      deferState(() => {
        setLevel(0);
        setStatus('idle');
      });
      return;
    }

    if (!navigator.mediaDevices?.getUserMedia) {
      deferState(() => setStatus('unsupported'));
      return;
    }

    let animationFrame = 0;
    let stream: MediaStream | null = null;
    let context: AudioContext | null = null;
    let disposed = false;

    const start = async () => {
      try {
        stream = await navigator.mediaDevices.getUserMedia({ audio: true });
        if (disposed) {
          stream.getTracks().forEach((track) => track.stop());
          return;
        }

        context = new AudioContext();
        const analyser = context.createAnalyser();
        analyser.fftSize = 256;
        const source = context.createMediaStreamSource(stream);
        source.connect(analyser);
        const data = new Uint8Array(analyser.frequencyBinCount);
        setStatus('listening');

        const tick = () => {
          analyser.getByteFrequencyData(data);
          const average = data.reduce((sum, value) => sum + value, 0) / data.length;
          setLevel(Math.min(100, Math.round((average / 140) * 100)));
          animationFrame = requestAnimationFrame(tick);
        };

        tick();
      } catch {
        setStatus('blocked');
        setLevel(0);
      }
    };

    void start();

    return () => {
      disposed = true;
      cancelAnimationFrame(animationFrame);
      stream?.getTracks().forEach((track) => track.stop());
      void context?.close();
    };
  }, [enabled]);

  return { level, status };
}
