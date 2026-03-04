(function () {
  var nav = document.querySelector('.top-nav');
  if (!nav) return;
  var btn = document.createElement('button');
  btn.className = 'nav-toggle';
  btn.setAttribute('aria-label', 'Toggle navigation');
  btn.setAttribute('aria-expanded', 'false');
  btn.innerHTML = '&#9776;';
  var siteLink = nav.querySelector('.site-link');
  if (siteLink) siteLink.insertAdjacentElement('afterend', btn);
  else nav.insertBefore(btn, nav.firstChild);
  btn.addEventListener('click', function () {
    var open = nav.classList.toggle('nav-open');
    btn.setAttribute('aria-expanded', open ? 'true' : 'false');
    btn.innerHTML = open ? '&#10005;' : '&#9776;';
  });
  document.addEventListener('click', function (e) {
    if (!nav.contains(e.target) && nav.classList.contains('nav-open')) {
      nav.classList.remove('nav-open');
      btn.setAttribute('aria-expanded', 'false');
      btn.innerHTML = '&#9776;';
    }
  });
})();
