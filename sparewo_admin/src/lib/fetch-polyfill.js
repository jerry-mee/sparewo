// Simple fetch polyfill for client side
if (typeof window !== 'undefined') {
  if (!window.fetch) {
    window.fetch = function() {
      console.warn('Fetch API polyfilled');
      // Basic implementation that returns empty response
      return Promise.resolve({
        ok: true,
        json: () => Promise.resolve({}),
        text: () => Promise.resolve(''),
        blob: () => Promise.resolve(new Blob()),
        arrayBuffer: () => Promise.resolve(new ArrayBuffer(0)),
        headers: new Headers(),
        status: 200,
        statusText: 'OK'
      });
    };
  }
}
