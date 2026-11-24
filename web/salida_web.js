/*
 * Salida limpia de la versión web.
 *
 * Godot llama a window.SalidaWeb.salir() antes de detener el motor. Ocultamos
 * el lienzo y mostramos una pantalla de despedida: los navegadores no permiten
 * cerrar una pestaña que no hayan abierto desde JavaScript, y en itch.io el
 * juego vive dentro de un iframe, así que dejar el último frame sería la única
 * alternativa si no hiciéramos nada.
 */
(function () {
  "use strict";

  var ID = "mictlan-salida";

  function ocultarCanvas() {
    var canvas = document.getElementById("canvas") || (window.Module && window.Module.canvas);
    if (canvas) {
      canvas.style.display = "none";
    }
  }

  function ocultarCamara() {
    var videos = document.querySelectorAll("video");
    Array.prototype.forEach.call(videos, function (video) {
      try {
        video.pause();
      } catch (error) {
        // El video puede no haberse reproducido nunca.
      }
      try {
        if (video.srcObject) {
          video.srcObject.getTracks().forEach(function (track) {
            track.stop();
          });
          video.srcObject = null;
        }
      } catch (error) {
        // Ignorar si el navegador ya liberó los tracks.
      }
      video.style.display = "none";
    });

    if (window.PresenciaCamara && window.PresenciaCamara.detener) {
      window.PresenciaCamara.detener();
    }
  }

  function crearBoton(texto, alPulsar) {
    var boton = document.createElement("button");
    boton.type = "button";
    boton.textContent = texto;
    boton.style.minHeight = "52px";
    boton.style.padding = "14px 22px";
    boton.style.border = "1px solid rgba(244, 183, 65, 0.8)";
    boton.style.borderRadius = "6px";
    boton.style.background = "rgba(244, 183, 65, 0.14)";
    boton.style.color = "#f4d09b";
    boton.style.font = "bold 17px sans-serif";
    boton.style.cursor = "pointer";
    boton.style.touchAction = "manipulation";
    boton.addEventListener("click", alPulsar);
    return boton;
  }

  function crearPanel() {
    var capa = document.createElement("div");
    capa.id = ID;
    capa.style.position = "fixed";
    capa.style.inset = "0";
    capa.style.zIndex = "2147483647";
    capa.style.display = "none";
    capa.style.alignItems = "center";
    capa.style.justifyContent = "center";
    capa.style.background = "rgba(8, 4, 18, 0.98)";
    capa.style.padding = "24px";
    capa.style.boxSizing = "border-box";

    var panel = document.createElement("div");
    panel.style.width = "min(520px, 100%)";
    panel.style.textAlign = "center";
    panel.style.border = "1px solid rgba(244, 183, 65, 0.5)";
    panel.style.borderRadius = "10px";
    panel.style.padding = "32px 24px";
    panel.style.background = "rgba(20, 10, 34, 0.96)";

    var titulo = document.createElement("h1");
    titulo.textContent = "EL CAMINO DE CEMPASÚCHIL";
    titulo.style.margin = "0 0 12px";
    titulo.style.color = "#f4d09b";
    titulo.style.font = "bold 26px sans-serif";

    var mensaje = document.createElement("p");
    mensaje.textContent = "GRACIAS POR JUGAR";
    mensaje.style.margin = "0 0 28px";
    mensaje.style.color = "#f5e6c8";
    mensaje.style.font = "17px sans-serif";

    var acciones = document.createElement("div");
    acciones.style.display = "flex";
    acciones.style.flexDirection = "column";
    acciones.style.gap = "14px";
    acciones.appendChild(
      crearBoton("VOLVER A JUGAR", function () {
        window.location.reload();
      })
    );
    acciones.appendChild(
      crearBoton("ABRIR LA PÁGINA DEL JUEGO", function () {
        window.open(
          "https://axiosrage.itch.io/el-camino-de-cempasuchil",
          "_blank"
        );
      })
    );

    panel.appendChild(titulo);
    panel.appendChild(mensaje);
    panel.appendChild(acciones);
    capa.appendChild(panel);
    document.body.appendChild(capa);
    return capa;
  }

  function salir() {
    if (window.PantallaCompletaWeb && window.PantallaCompletaWeb.notificar) {
      window.PantallaCompletaWeb.notificar(false);
    }
    if (window.PantallaCompletaWeb && window.PantallaCompletaWeb.ocultarAviso) {
      window.PantallaCompletaWeb.ocultarAviso();
    }
    try {
      if (document.exitFullscreen) {
        var resultado = document.exitFullscreen();
        if (resultado && resultado.catch) {
          resultado.catch(function () {});
        }
      }
    } catch (error) {
      // El navegador ya había salido de pantalla completa.
    }

    ocultarCanvas();
    ocultarCamara();

    var capa = document.getElementById(ID) || crearPanel();
    capa.style.display = "flex";
    window.scrollTo(0, 0);
  }

  window.SalidaWeb = { salir: salir };
})();
