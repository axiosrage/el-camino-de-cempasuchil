/*
 * Detección de presencia con MediaPipe Face Detector (BlazeFace).
 * Todo se procesa en el navegador: no se graba ni se envía ninguna imagen.
 *
 * API para Godot:
 *   window.PresenciaCamara.solicitarPermiso()
 *   window.PresenciaCamara.iniciar()
 *   window.PresenciaCamara.detener()
 *   window.PresenciaCamara.liberar()
 *   window.PresenciaCamara.estadoJSON()
 */
(function () {
  "use strict";

  const estado = {
    estado: "apagado",
    mensaje: "",
    presencia: false,
    confianza: 0,
    latencia_ms: 0,
    fps: 0,
    permiso: "desconocido",
    modo: "desconocido",
    error: "",
    detecciones: 0,
  };

  let detector = null;
  let vision = null;
  let stream = null;
  let video = null;
  let canvas = null;
  let ctx = null;
  let loopId = 0;
  let activo = false;
  let pausaVisibilidad = false;
  let ultimoFrame = 0;
  let fpsInicio = 0;
  let fpsCuadros = 0;
  let historial = [];

  function publicar(nuevoEstado, mensaje) {
    estado.estado = nuevoEstado;
    if (mensaje !== undefined) {
      estado.mensaje = mensaje;
    }
    estado.error = nuevoEstado === "error" ? String(mensaje || "") : "";
  }

  function enIframe() {
    try {
      return window.self !== window.top;
    } catch (error) {
      return true;
    }
  }

  function clasificarError(error) {
    const nombre = (error && error.name) || "";
    if (nombre === "NotAllowedError" || nombre === "SecurityError") {
      estado.permiso = "denegado";
      if (enIframe()) {
        return [
          "sin_permiso",
          "El navegador bloqueó la cámara. Abre el juego en una pestaña nueva.",
        ];
      }
      return ["sin_permiso", "Permiso de cámara denegado. Revisa el navegador."];
    }
    if (nombre === "NotFoundError" || nombre === "OverconstrainedError") {
      return ["no_disponible", "No se encontró una cámara."];
    }
    if (nombre === "NotReadableError" || nombre === "AbortError") {
      return ["error", "La cámara está siendo usada por otro programa."];
    }
    return [
      "error",
      "No se pudo iniciar la cámara: " + (error && error.message ? error.message : error),
    ];
  }

  function crearVideo() {
    if (video) {
      return;
    }
    video = document.createElement("video");
    video.setAttribute("playsinline", "");
    video.setAttribute("muted", "");
    video.muted = true;
    video.autoplay = true;
    video.style.position = "fixed";
    video.style.left = "-10px";
    video.style.top = "-10px";
    video.style.width = "1px";
    video.style.height = "1px";
    video.style.opacity = "0.01";
    video.style.pointerEvents = "none";
    document.body.appendChild(video);
  }

  function crearCanvas() {
    if (canvas) {
      return;
    }
    canvas = document.createElement("canvas");
    canvas.width = 320;
    canvas.height = 240;
    ctx = canvas.getContext("2d");
  }

  async function abrirCamara() {
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      throw Object.assign(new Error("getUserMedia no está disponible"), {
        name: "NotFoundError",
      });
    }
    return navigator.mediaDevices.getUserMedia({
      audio: false,
      video: {
        facingMode: "user",
        width: { ideal: 320 },
        height: { ideal: 240 },
        frameRate: { ideal: 15, max: 30 },
      },
    });
  }

  async function cargarModelo() {
    if (detector) {
      return;
    }
    publicar("cargando", "Cargando modelo de visión…");
    const mp = await import("./mediapipe/vision_bundle.js");
    vision = await mp.FilesetResolver.forVisionTasks("./mediapipe/wasm");
    detector = await mp.FaceDetector.createFromOptions(vision, {
      baseOptions: {
        modelAssetPath: "./mediapipe/blaze_face_short_range.tflite",
        delegate: "CPU",
      },
      runningMode: "VIDEO",
      minDetectionConfidence: 0.6,
      minSuppressionThreshold: 0.3,
    });
    estado.modo = "MediaPipe Face Detector (BlazeFace)";
    publicar("cargando", "Modelo cargado.");
  }

  async function iniciar() {
    if (activo) {
      return;
    }
    try {
      publicar("solicitando", "Solicitando cámara…");
      crearVideo();
      crearCanvas();

      if (!stream) {
        stream = await abrirCamara();
      }
      estado.permiso = "concedido";
      video.srcObject = stream;
      await video.play();

      await cargarModelo();

      activo = true;
      estado.presencia = false;
      estado.confianza = 0;
      estado.latencia_ms = 0;
      estado.fps = 0;
      estado.detecciones = 0;
      historial = [];
      ultimoFrame = 0;
      fpsCuadros = 0;
      fpsInicio = performance.now();
      publicar("activo", "");

      if (!loopId) {
        loopId = requestAnimationFrame(bucle);
      }
    } catch (error) {
      const [nuevoEstado, mensaje] = clasificarError(error);
      publicar(nuevoEstado, mensaje);
      activo = false;
      detenerStream();
      if (loopId) {
        cancelAnimationFrame(loopId);
        loopId = 0;
      }
    }
  }

  function bucle(ts) {
    if (!activo) {
      loopId = 0;
      return;
    }
    loopId = requestAnimationFrame(bucle);

    // Aproximadamente 6 detecciones por segundo.
    if (ts - ultimoFrame < 160) {
      return;
    }
    ultimoFrame = ts;

    if (!detector || !video || video.readyState < 2) {
      return;
    }

    try {
      ctx.drawImage(video, 0, 0, canvas.width, canvas.height);
      const inicio = performance.now();
      const resultado = detector.detectForVideo(canvas, ts);
      estado.latencia_ms = Math.round(performance.now() - inicio);

      const detecciones = resultado.detections || [];
      estado.detecciones = detecciones.length;

      let score = 0;
      if (detecciones.length > 0) {
        score = Math.max(...detecciones.map((d) => d.categories[0].score));
      }
      estado.confianza = Number(score.toFixed(3));

      // 2 de los últimos 3 cuadros: evita falsos positivos aislados.
      historial.push(detecciones.length > 0);
      if (historial.length > 3) {
        historial.shift();
      }
      estado.presencia = historial.filter(Boolean).length >= 2;

      fpsCuadros++;
      const ahora = performance.now();
      if (ahora - fpsInicio >= 1000) {
        estado.fps = Number(((fpsCuadros * 1000) / (ahora - fpsInicio)).toFixed(1));
        fpsCuadros = 0;
        fpsInicio = ahora;
      }
    } catch (error) {
      publicar(
        "error",
        "Error al procesar la cámara: " + (error && error.message ? error.message : error)
      );
      activo = false;
      detenerStream();
    }
  }

  function detenerStream() {
    if (stream) {
      stream.getTracks().forEach((track) => track.stop());
      stream = null;
    }
    if (video) {
      try {
        video.pause();
      } catch (error) {
        // Ignorar: el video puede no haber llegado a reproducirse.
      }
      video.srcObject = null;
    }
  }

  function detener() {
    activo = false;
    pausaVisibilidad = false;
    if (loopId) {
      cancelAnimationFrame(loopId);
      loopId = 0;
    }
    detenerStream();
    estado.presencia = false;
    estado.confianza = 0;
    estado.latencia_ms = 0;
    estado.fps = 0;
    estado.detecciones = 0;
    historial = [];
    publicar("apagado", "");
  }

  async function solicitarPermiso() {
    try {
      publicar("solicitando", "Solicitando permiso…");
      const prueba = await abrirCamara();
      prueba.getTracks().forEach((track) => track.stop());
      estado.permiso = "concedido";
      publicar("listo", "Permiso concedido.");
    } catch (error) {
      const [nuevoEstado, mensaje] = clasificarError(error);
      publicar(nuevoEstado, mensaje);
    }
  }

  function liberar() {
    detener();
    if (detector) {
      try {
        detector.close();
      } catch (error) {
        // Ignorar: el detector puede haberse cerrado ya.
      }
      detector = null;
    }
    vision = null;
    estado.modo = "desconocido";
    estado.estado = "apagado";
    estado.mensaje = "";
  }

  document.addEventListener("visibilitychange", function () {
    if (document.hidden) {
      if (activo) {
        pausaVisibilidad = true;
        activo = false;
        if (loopId) {
          cancelAnimationFrame(loopId);
          loopId = 0;
        }
        detenerStream();
        estado.presencia = false;
        estado.confianza = 0;
        estado.detecciones = 0;
        estado.fps = 0;
      }
    } else if (pausaVisibilidad) {
      pausaVisibilidad = false;
      iniciar();
    }
  });

  window.addEventListener("pagehide", detener);

  window.PresenciaCamara = {
    solicitarPermiso,
    iniciar,
    detener,
    liberar,
    estadoJSON: function () {
      return JSON.stringify(estado);
    },
    estado,
  };
})();
