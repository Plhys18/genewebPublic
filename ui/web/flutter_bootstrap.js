{{flutter_js}}
{{flutter_build_config}}

const loadingDiv = document.querySelector('#loading');
const appVersionDiv = document.querySelector('#app_version');

// Function to fetch and display the version
async function displayAppVersion() {
  try {
    const response = await fetch('/version.json');
    const versionData = await response.json();
    appVersionDiv.textContent = `${versionData.version}`;
  } catch (error) {
    console.error('Failed to load version information:', error);
  }
}

displayAppVersion();

_flutter.loader.load({
  onEntrypointLoaded: async function(engineInitializer) {
    loadingDiv.classList.add('main_done');
    const appRunner = await engineInitializer.initializeEngine();
    console.log('Engine initialized');

    loadingDiv.classList.add('init_done');
    await appRunner.runApp();
    console.log('App started');

    window.setTimeout(function () {
      loadingDiv.remove();
      appVersionDiv.remove();
      console.log('App loading indicator removed');
    }, 500);
  },
});
