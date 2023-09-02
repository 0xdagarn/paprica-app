// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"
import {Metamask} from "./hooks/metamask"

let Hooks = {};
Hooks.Metamask = Metamask

Hooks.ScrollToBottom = {
  mounted() {
    this.el.scrollTop = this.el.scrollHeight;
  },
  updated() {
    this.el.scrollTop = this.el.scrollHeight;
  }
}

Hooks.StartCamera = {
  mounted() {
    let hook = this;
    const video = this.el;
    navigator.mediaDevices
      .getUserMedia({
        audio: true,
        video: true,
      })
      .then((cameraStream) => {
        video.srcObject = cameraStream;
        video.onloadedmetadata = function (e) {
          video.play();
          let mediaRecorder = new MediaRecorder(cameraStream, {
            mimeType: "video/webm",
            videoBitsPerSecond: 3000000,
          });
          mediaRecorder.ondataavailable = (e) => {
            var reader = new FileReader();
            reader.onloadend = function () {
              // hook.pushEvent("video_data", { data: reader.result });
            };
            reader.readAsDataURL(e.data);
          };
          mediaRecorder.start(1000);
        };
      });
  },
};

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  hooks: Hooks
});

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

