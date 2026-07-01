(function () {
  const players = new WeakMap();

  function paintMessage(container, message) {
    container.innerHTML = '';
    const panel = document.createElement('div');
    panel.style.cssText = [
      'display:flex',
      'align-items:center',
      'justify-content:center',
      'width:100%',
      'height:100%',
      'background:linear-gradient(180deg,#050a14 0%,#000 100%)',
      'color:#d9f7ff',
      'font-family:system-ui,sans-serif',
      'font-size:14px',
      'text-align:center',
      'padding:24px'
    ].join(';');
    panel.textContent = message;
    container.appendChild(panel);
  }

  async function destroy(container) {
    const current = players.get(container);
    if (!current) {
      container.innerHTML = '';
      return;
    }

    players.delete(container);
    try {
      await current.player.destroy();
    } catch (_) {}
    container.innerHTML = '';
  }

  async function mount(container, config) {
    await destroy(container);

    if (!window.shaka) {
      paintMessage(container, 'Shaka Player failed to load.');
      return;
    }

    window.shaka.polyfill.installAll();
    if (!window.shaka.Player.isBrowserSupported()) {
      paintMessage(container, 'This browser does not support protected playback.');
      return;
    }

    const video = document.createElement('video');
    video.controls = true;
    video.autoplay = config.autoplay !== false;
    video.playsInline = true;
    video.preload = 'auto';
    video.style.width = '100%';
    video.style.height = '100%';
    video.style.objectFit = 'cover';
    video.style.background = '#000';

    container.innerHTML = '';
    container.appendChild(video);

    const player = new window.shaka.Player(video);
    players.set(container, { player, video });

    player.addEventListener('error', (event) => {
      const detail = event && event.detail ? event.detail : {};
      console.error('DFC Shaka error', detail);
      paintMessage(container, detail.message || 'Protected stream unavailable.');
    });

    const servers = {};
    if (config.widevineLicenseUrl) {
      servers['com.widevine.alpha'] = config.widevineLicenseUrl;
    }
    if (config.fairplayLicenseUrl) {
      servers['com.apple.fps'] = config.fairplayLicenseUrl;
    }

    const drmConfig = {
      servers,
      advanced: {},
    };
    if (config.fairplayCertificateUrl) {
      drmConfig.advanced['com.apple.fps'] = {
        serverCertificateUri: config.fairplayCertificateUrl,
      };
    }

    player.configure({
      drm: drmConfig,
      streaming: {
        lowLatencyMode: !!config.isLive,
        bufferingGoal: config.isLive ? 8 : 15,
        rebufferingGoal: 2,
      },
    });

    const networkingEngine = player.getNetworkingEngine();
    if (networkingEngine && config.drmToken) {
      networkingEngine.registerRequestFilter((type, request) => {
        if (type === window.shaka.net.NetworkingEngine.RequestType.LICENSE) {
          request.headers['Authorization'] = `Bearer ${config.drmToken}`;
        }
      });
    }

    try {
      await player.load(config.manifestUrl);
      if (config.autoplay !== false) {
        try {
          await video.play();
        } catch (_) {}
      }
    } catch (error) {
      console.error('DFC Shaka load failed', error);
      paintMessage(container, 'Failed to load protected stream.');
    }
  }

  async function update(container, config) {
    await mount(container, config);
  }

  window.dfcShakaPlayer = {
    mount,
    update,
    destroy,
  };
})();
