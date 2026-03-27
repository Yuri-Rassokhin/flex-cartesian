const topbar = document.querySelector('.topbar');
const navToggle = document.querySelector('.nav-toggle');
const navLinks = document.querySelectorAll('.nav a');

if (navToggle) {
  navToggle.addEventListener('click', () => {
    const open = topbar.classList.toggle('nav-open');
    navToggle.setAttribute('aria-expanded', String(open));
  });
}

navLinks.forEach(link => {
  link.addEventListener('click', () => {
    topbar.classList.remove('nav-open');
    if (navToggle) navToggle.setAttribute('aria-expanded', 'false');
  });
});

const sceneTabs = document.querySelectorAll('.scene-tab');
const scenes = document.querySelectorAll('.scene');
const progress = document.querySelector('.scene-progress span');
let activeScene = 0;
let sceneTimer = null;

function setScene(index, resetTimer = true) {
  activeScene = index;
  sceneTabs.forEach((tab, i) => tab.classList.toggle('active', i === index));
  scenes.forEach((scene, i) => scene.classList.toggle('active', i === index));
  if (progress) {
    progress.style.transform = `translateX(${index * 100}%)`;
  }
  if (resetTimer) startSceneLoop();
}

function startSceneLoop() {
  if (sceneTimer) clearInterval(sceneTimer);
  sceneTimer = setInterval(() => {
    const next = (activeScene + 1) % scenes.length;
    setScene(next, false);
  }, 3600);
}

sceneTabs.forEach((tab, i) => {
  tab.addEventListener('click', () => setScene(i, true));
});

setScene(0, false);
startSceneLoop();

const observer = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      entry.target.classList.add('in-view');
      observer.unobserve(entry.target);
    }
  });
}, { threshold: 0.16 });

document.querySelectorAll('.reveal').forEach(el => observer.observe(el));
