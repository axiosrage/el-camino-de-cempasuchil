/*
 * Mantiene la pantalla completa en la versión web cuando se pulsa Esc.
 *
 * Godot avisa de la preferencia del jugador con:
 *   window.PantallaCompletaWeb.notificar(true | false)
 *
 * El navegador reserva Esc para salir de pantalla completa. Cuando está
 * disponible, Keyboard Lock captura esa tecla para que el juego la reciba sin
 * abandonar el modo pantalla completa. Si no está disponible, se vuelve a
 * pedir el modo pantalla completa y se muestra un aviso pulsable.
 */
(function () {
  "use strict";

  var deseado = !!window.__mictlanPantallaCompletaDeseada;
  var aviso = null;

  function elemento() {
    return (
      document.getElementById("canvas") ||
      (window.Module && window.Module.canvas) ||
      document.documentElement
    );
  }

  function bloquearEscape() {
    if (!navigator.keyboard || !navigator.keyboard.lock) {
      return;
    }
    try {
      navigator.keyboard.lock(["Escape"]);
    } catch (error) {
      // Firefox y Safari no ofrecen esta API: se usa el respaldo.
    }
  }

  function desbloquearEscape() {
    if (!navigator.keyboard || !navigator.keyboard.unlock) {
      return;
    }
    try {
      navigator.keyboard.unlock();
    } catch (error) {
      // No hacer nada si el navegador ya liberó las teclas.
    }
  }

  function mostrarAviso() {
    if (aviso) {
      aviso.style.display = "block";
      return;
    }
    aviso = document.createElement("div");
    aviso.textContent = "PULSA AQUÍ PARA VOLVER A PANTALLA COMPLETA";
    aviso.style.position = "fixed";
    aviso.style.left = "50%";
    aviso.style.bottom = "16px";
    aviso.style.transform = "translateX(-50%)";
    aviso.style.zIndex = "2147483647";
    aviso.style.padding = "10px 18px";
    aviso.style.background = "rgba(12, 6, 24, 0.92)";
    aviso.style.border = "1px solid rgba(244, 183, 65, 0.7)";
    aviso.style.color = "#f4d09b";
    aviso.style.font = "14px sans-serif";
    aviso.style.cursor = "pointer";
    aviso.style.whiteSpace = "nowrap";
    aviso.addEventListener("click", function () {
      aviso.style.display = "none";
      pedirPantallaCompleta();
    });
    document.body.appendChild(aviso);
  }

  function ocultarAviso() {
    if (aviso) {
      aviso.style.display = "none";
    }
  }

  function pedirPantallaCompleta() {
    var objetivo = elemento();
    if (!document.fullscreenElement && objetivo && objetivo.requestFullscreen) {
      var resultado;
      try {
        resultado = objetivo.requestFullscreen();
      } catch (error) {
        mostrarAviso();
        return;
      }
      Promise.resolve(resultado)
        .then(function () {
          bloquearEscape();
        })
        .catch(function () {
          mostrarAviso();
        });
      return;
    }
    bloquearEscape();
  }

  document.addEventListener(
    "fullscreenchange",
    function () {
      if (document.fullscreenElement) {
        ocultarAviso();
        if (deseado) {
          bloquearEscape();
        }
        return;
      }

      if (deseado) {
        // El jugador no pidió salir desde Ajustes: recuperamos el modo.
        pedirPantallaCompleta();
      }
    },
    true
  );

  document.addEventListener(
    "keydown",
    function (evento) {
      if (!deseado || !document.fullscreenElement) {
        return;
      }
      if (evento.key === "Escape" || evento.code === "Escape") {
        // Con Keyboard Lock esto evita que el navegador salga del modo;
        // el evento sigue llegando a Godot para abrir el menú.
        evento.preventDefault();
      }
    },
    true
  );

  window.PantallaCompletaWeb = {
    notificar: function (activa) {
      deseado = !!activa;
      window.__mictlanPantallaCompletaDeseada = deseado;
      if (deseado) {
        if (document.fullscreenElement) {
          bloquearEscape();
        }
      } else {
        desbloquearEscape();
        ocultarAviso();
      }
    },
    estaActiva: function () {
      return deseado;
    },
    ocultarAviso: ocultarAviso,
  };

  if (deseado && document.fullscreenElement) {
    bloquearEscape();
  }
})();
