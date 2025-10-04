// app/javascript/controllers/home_animation_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("Home animation controller connected!")
    
    // Put your animation logic here — for example:
    const animationStyles = `
      @keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }
      @keyframes fadeInUp { from { opacity: 0; transform: translateY(20px); } to { opacity: 1; transform: translateY(0); } }
      .animate-fade-in { animation: fadeIn 1s ease-out forwards; }
      .animate-fade-in-up { animation: fadeInUp 0.8s ease-out forwards; }
    `;
    const styleSheet = document.createElement("style");
    styleSheet.innerText = animationStyles;
    document.head.appendChild(styleSheet);

    const animatedElements = document.querySelectorAll("[data-animate]");
    // const observer = new IntersectionObserver((entries) => {
    //   entries.forEach((entry) => {
    //     if (entry.isIntersecting) {
    //       entry.target.classList.add("is-visible");
    //       observer.unobserve(entry.target);
    //     }
    //   });
    // }, { threshold: 0.1 });
    // animatedElements.forEach((el) => observer.observe(el));

    const observer = new IntersectionObserver((entries) => {
    entries.forEach((entry) => {
        if (entry.isIntersecting) {
        const animationType = entry.target.dataset.animate; // e.g., "fade-in-up"
        entry.target.classList.add(`animate-${animationType}`);
        observer.unobserve(entry.target);
        }
    });
    }, { threshold: 0.1 });

    animatedElements.forEach((el) => observer.observe(el));
  }
}
