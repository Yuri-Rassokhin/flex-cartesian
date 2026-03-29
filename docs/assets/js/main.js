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

// Находим все секции, у которых есть атрибут id (Concept, Workflow и т.д.)
const sections = document.querySelectorAll('section[id]');

// Исключаем из отслеживания кнопку GitHub (класс .nav-cta), берем только текстовые ссылки
const navItems = document.querySelectorAll('.nav a:not(.nav-cta)');

// Настройки обсервера: секция считается активной, когда она пересекает центр экрана
const observerOptions = {
  root: null,
  rootMargin: '-20% 0px -60% 0px', 
  threshold: 0
};

const scrollSpyObserver = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    // Если секция находится в видимой области
    if (entry.isIntersecting) {
      const id = entry.target.getAttribute('id');
      
      // Снимаем класс active со всех ссылок...
      navItems.forEach(link => {
        link.classList.remove('active');
        // ...и добавляем только той, href которой совпадает с id секции
        if (link.getAttribute('href') === `#${id}`) {
          link.classList.add('active');
        }
      });
    }
  });
}, observerOptions);

// Запускаем наблюдение за каждой секцией
sections.forEach(section => {
  scrollSpyObserver.observe(section);
});
