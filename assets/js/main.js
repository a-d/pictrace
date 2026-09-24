/* Main site JavaScript */

/* ========================================
   Journey map functionality
   ======================================== */

/* Progress mapping function factory for smooth animation */
/* Uses Catmull-Rom spline interpolation for smooth curves */
function makeProgressMapper(points) {
  return function(t) {
    if (t <= points[0][0]) return points[0][1];
    if (t >= points[points.length - 1][0]) return points[points.length - 1][1];

    var i = 1;
    while (i < points.length && t > points[i][0]) i++;
    var p0 = points[Math.max(i - 2, 0)];
    var p1 = points[i - 1];
    var p2 = points[i];
    var p3 = points[Math.min(i + 1, points.length - 1)];

    var u = (t - p1[0]) / (p2[0] - p1[0]);

    /* Catmull-Rom spline */
    var y =
      0.5 *
      ((2 * p1[1]) +
        (-p0[1] + p2[1]) * u +
        (2 * p0[1] - 5 * p1[1] + 4 * p2[1] - p3[1]) * u * u +
        (-p0[1] + 3 * p1[1] - 3 * p2[1] + p3[1]) * u * u * u);

    return Math.min(1, Math.max(0, y));
  };
}

/* Register journey progress functions from data-progress attributes */
/* (progressively injected location batches cannot run inline scripts, so the */
/* coordinate arrays live in markup and are parsed here) */
function registerJourneyProgress() {
  document.querySelectorAll('.map[pathId][data-progress]').forEach(function(mapElement) {
    if (mapElement.dataset.progressRegistered) return;
    mapElement.dataset.progressRegistered = 'true';
    var fnName = mapElement.getAttribute('progressFn');
    if (!fnName) return;
    try {
      window[fnName] = makeProgressMapper(JSON.parse(mapElement.getAttribute('data-progress')));
    } catch (err) {
      window[fnName] = null;
    }
  });
}
registerJourneyProgress();

(function() {
  /* Only define once */
  if (window.journeyMapInitialized) return;
  window.journeyMapInitialized = true;

  /* Default linear progress (can be overridden per journey) */
  var defaultProgress = function(t) { return t; };

  /* Check if CSS scroll-driven animations are supported (named view timeline) */
  var supportsScrollTimeline = CSS.supports('view-timeline-name', '--test');

  var maps = [];
  var gridLayoutInitialized = false;
  var pathAnimationInitialized = false;

  /* Initialize all journey maps - runs for ALL browsers */
  /* This only sets up data structures, no layout measurements */
  function initJourneyMaps() {
    document.querySelectorAll('.map[pathId]').forEach(function(mapElement) {
      if (mapElement.dataset.journeyInitialized) return;
      mapElement.dataset.journeyInitialized = 'true';

      var pathId = mapElement.getAttribute('pathId');
      var path = mapElement.querySelector('path[id="' + pathId + '"]');

      /* Get journey-specific progress mapper if defined, otherwise use default */
      var progressFnName = mapElement.getAttribute('progressFn');
      var progressFn = (progressFnName && window[progressFnName]) ? window[progressFnName] : defaultProgress;

      var mapData = {
        element: mapElement,
        path: path,
        pathLength: 0, /* Calculated lazily on first animation */
        count: parseInt(mapElement.getAttribute('count'), 10) || 10,
        progressFn: progressFn
      };

      /* Path length calculation deferred to first animation frame */

      maps.push(mapData);
    });
  }

  /* Update grid layout - runs for ALL browsers */
  /* Uses getComputedStyle - deferred until after images load */
  function updateGridLayout() {
    var gallery = document.querySelector('.gallery');
    var columns = gallery ? getComputedStyle(gallery).gridTemplateColumns.split(' ').length - 1 : 1;
    maps.forEach(function(map) {
      map.element.style.gridRow = 'span ' + Math.ceil(map.count / columns);
    });
    gridLayoutInitialized = true;
  }

  /* Initialize path for animation - calculates path length on demand */
  /* Runs for ALL browsers to set up stroke-dasharray and --path-length */
  function ensurePathInitialized(mapData) {
    if (mapData.path && mapData.pathLength === 0) {
      mapData.pathLength = mapData.path.getTotalLength();
      mapData.path.style.strokeDasharray = mapData.pathLength;
      /* Set CSS custom property for CSS scroll-driven animations */
      mapData.path.style.setProperty('--path-length', mapData.pathLength);
      /* For JS fallback: set initial offset to full length (hidden) */
      if (!supportsScrollTimeline) {
        mapData.path.style.strokeDashoffset = mapData.pathLength;
      }
    }
  }

  /* Update path animation - only for fallback browsers */
  /* Uses getBoundingClientRect - deferred until first scroll */
  function updatePathAnimation() {
    if (supportsScrollTimeline) return;

    pathAnimationInitialized = true;
    var windowHeight = window.innerHeight;
    maps.forEach(function(map) {
      if (!map.path) return;

      /* Lazy initialization of path length */
      ensurePathInitialized(map);
      if (!map.pathLength) return;

      var rect = map.element.getBoundingClientRect();
      var totalDistance = rect.bottom - rect.top;
      var scrolledDistance = windowHeight - rect.top;

      var scrollPercent = 0;
      if (totalDistance > 0) {
        scrollPercent = Math.max(0, Math.min(1, scrolledDistance / totalDistance));
      }
      /* Use journey-specific progress function */
      scrollPercent = map.progressFn(scrollPercent);

      var drawLength = map.pathLength * scrollPercent;
      map.path.style.strokeDashoffset = map.pathLength - drawLength;
    });
  }

  /* Initialize data structures on DOM ready (no layout measurements) */
  function initOnDomReady() {
    initJourneyMaps();
  }

  /* Initialize layout after images load (deferred layout measurements) */
  function initOnLoad() {
    /* Only run updateGridLayout if maps exist */
    if (maps.length > 0 && !gridLayoutInitialized) {
      updateGridLayout();
    }
    /* Initialize path properties for ALL browsers (needed for CSS scroll animations) */
    maps.forEach(ensurePathInitialized);
  }

  /* Initialize path animation on first scroll (deferred until interaction) */
  function initOnFirstScroll() {
    if (!pathAnimationInitialized && maps.length > 0) {
      updatePathAnimation();
    }
  }

  /* Initialize on DOM ready - only data structures, no measurements */
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initOnDomReady);
  } else {
    initOnDomReady();
  }

  /* Defer layout measurements until after images load */
  if (document.readyState === 'complete') {
    initOnLoad();
  } else {
    window.addEventListener('load', initOnLoad);
  }

  /* Event listeners */
  window.addEventListener('scroll', function() {
    initOnFirstScroll();
    updatePathAnimation();
  }, { passive: true });

  window.addEventListener('resize', function() {
    initJourneyMaps();
    updateGridLayout();
    updatePathAnimation();
  });

  /* Re-init hook for progressively injected location batches (PT16) */
  window.refreshJourneyMaps = function() {
    registerJourneyProgress();
    initJourneyMaps();
    updateGridLayout();
    updatePathAnimation();
  };
})();

/* ========================================
   Gallery and EXIF functionality
   ======================================== */

document.addEventListener('DOMContentLoaded', function() {
  /* add location scrolling indicator */
  {
    var locationIndicator = document.getElementById("location-indicator");
    if (locationIndicator) {
      var locationObserver = new IntersectionObserver(function(entries) {
        entries.forEach(function(entry) {
          if (entry.isIntersecting) {
            locationIndicator.style.opacity = 1;
            locationIndicator.textContent = entry.target.getAttribute("location");
          }
        });
      }, { threshold: 1 }); /* 100% visible */

      /* observe every gallery item once; injected batches re-use this (PT16) */
      window.observeLocationItems = function(root) {
        (root || document).querySelectorAll(".gallery .gallery-item").forEach(function(sec) {
          if (sec.dataset.locationObserved) return;
          sec.dataset.locationObserved = "true";
          locationObserver.observe(sec);
        });
      };
      window.observeLocationItems();

      var timer = setTimeout(function() { locationIndicator.style.opacity = 0; }, 100);
      window.addEventListener("scroll", function() {
        locationIndicator.style.opacity = 1;
        clearTimeout(timer);
        timer = setTimeout(function() { locationIndicator.style.opacity = 0; }, 1000);
      });
    }
  }

  /* Add click event listeners to all gallery links */
  var closeLink = document.querySelector('a.close');
  if (closeLink) {
    document.querySelectorAll('.gallery-item > a > picture').forEach(function(pic) {
      pic.parentElement.addEventListener('click', function(event) {
        closeLink.setAttribute('href', window.location.hash || '#p');
      });
    });
  }

  /* Keyboard navigation for the lightbox (arrow keys mirror the nav buttons) */
  {
    document.addEventListener('keydown', function(event) {
      if (event.key !== 'ArrowLeft' && event.key !== 'ArrowRight') return;
      if (event.ctrlKey || event.metaKey || event.altKey || event.shiftKey) return;

      var slide = document.querySelector('.lightbox-container:target');
      if (!slide) return;

      /* A slide is open: own the arrow keys, then follow the matching link */
      event.preventDefault();

      var arrow = slide.querySelector(event.key === 'ArrowLeft' ? '.nav-prev' : '.nav-next');
      if (arrow) arrow.click();
    });
  }

  /* Horizontal scroll navigation for the lightbox (trackpad swipes / horizontal wheel) */
  {
    var wheelSum = 0;
    var wheelLocked = false;
    var wheelQuiet = null;

    document.addEventListener('wheel', function(event) {
      if (event.ctrlKey || event.metaKey) return; /* pinch-zoom / browser gestures */

      var dx = event.deltaX;
      if (event.shiftKey && Math.abs(dx) < Math.abs(event.deltaY)) dx = event.deltaY; /* classic mouse: shift+wheel is horizontal */
      if (event.deltaMode === 1) dx = dx * 16; /* line-based deltas (Firefox): ~16 px per line */
      if (Math.abs(dx) < 4) return;
      if (!event.shiftKey && Math.abs(dx) <= Math.abs(event.deltaY)) return;

      var slide = document.querySelector('.lightbox-container:target');
      if (!slide) return;

      if (!wheelLocked) {
        wheelSum += dx;
        if (Math.abs(wheelSum) >= 45) {
          wheelLocked = true; /* one step per gesture - absorb the trackpad inertia tail */
          var arrow = slide.querySelector(wheelSum > 0 ? '.nav-next' : '.nav-prev');
          wheelSum = 0;
          if (arrow) arrow.click();
        }
      }

      window.clearTimeout(wheelQuiet);
      wheelQuiet = window.setTimeout(function() {
        wheelSum = 0;
        wheelLocked = false;
      }, 220);
    }, { passive: true });
  }

  /* Swipe navigation for the lightbox (one-finger horizontal swipes on touch screens) */
  {
    var SWIPE_MIN_X = 50; /* px a gesture must travel horizontally to count */
    var touchStartX = 0;
    var touchStartY = 0;
    var touchTracking = false;

    document.addEventListener('touchstart', function(event) {
      touchTracking = false;
      if (event.touches.length !== 1) return; /* multi-touch = pinch/pan (PT6) */

      /* Only a touch that starts on the arrow's own (visible) box keeps tap
         behaviour: the arrows' oversized ::before zones cover most of the
         screen on touch devices, so matching them here swallowed every swipe
         (on phones the mobile zone is the whole viewport and the arrow box is
         0 x 0, so swipes are always tracked there). */
      var touch = event.touches[0];
      var arrow = (event.target && event.target.closest) ? event.target.closest('.nav-prev, .nav-next') : null;
      if (arrow) {
        var box = arrow.getBoundingClientRect();
        if (box.width > 0 && box.height > 0 &&
            touch.clientX >= box.left && touch.clientX <= box.right &&
            touch.clientY >= box.top && touch.clientY <= box.bottom) return;
      }

      touchTracking = true;
      touchStartX = touch.clientX;
      touchStartY = touch.clientY;
    }, { passive: true });

    document.addEventListener('touchcancel', function() {
      touchTracking = false; /* the browser took the gesture over (scroll / zoom) */
    }, { passive: true });

    document.addEventListener('touchend', function(event) {
      if (!touchTracking) return;
      touchTracking = false;
      if (event.touches.length !== 0) return;

      var touch = event.changedTouches[0];
      var dx = touch.clientX - touchStartX;
      var dy = touch.clientY - touchStartY;
      if (Math.abs(dx) < SWIPE_MIN_X || Math.abs(dx) < Math.abs(dy) * 1.5) return;

      var slide = document.querySelector('.lightbox-container:target');
      if (!slide) return;

      var arrow = slide.querySelector(dx < 0 ? '.nav-next' : '.nav-prev');
      if (arrow) arrow.click();
    }, { passive: true });
  }

  /* Reset the page pinch-zoom when the lightbox closes: zoom is allowed on the
     opened image only, and the gallery blocks pinch, so a leftover zoom could
     not be undone by the visitor. A brief viewport-meta flip (maximum-scale=1)
     clamps the page scale back to 1; it must land BEFORE the close navigation
     runs (hence the click capture - a hashchange-time flip comes too late for
     tap closes), and the restore is deferred a tick because same-tick flips
     are coalesced away. */
  {
    var viewportMeta = document.querySelector('meta[name="viewport"]');
    var viewportBase = viewportMeta ? viewportMeta.getAttribute('content') : '';
    var zoomRestoreTimer = null;

    var resetPageZoom = function() {
      if (!viewportMeta) return;
      viewportMeta.setAttribute('content', viewportBase + ', maximum-scale=1');
      window.clearTimeout(zoomRestoreTimer);
      zoomRestoreTimer = window.setTimeout(function() {
        viewportMeta.setAttribute('content', viewportBase);
      }, 120);
    };

    /* Every lightbox close is a click on the .close catcher (tap or mouse) */
    document.addEventListener('click', function(event) {
      if (event.target && event.target.closest && event.target.closest('a.close')) resetPageZoom();
    }, true);

    /* Fallback for closes that bypass the catcher (e.g. back navigation) */
    var slideWasOpen = !!document.querySelector('.lightbox-container:target');
    window.addEventListener('hashchange', function() {
      var slideOpen = !!document.querySelector('.lightbox-container:target');
      if (slideWasOpen && !slideOpen) resetPageZoom();
      slideWasOpen = slideOpen;
    });
  }

  /* ========================================
     Hover-based popover for mouse devices
     ======================================== */
  {
    /* Check for hover capability using CSS media queries */
    var hasHover = window.matchMedia('(hover: hover)').matches;
    var hasFinePointer = window.matchMedia('(pointer: fine)').matches;
    var supportsHover = hasHover && hasFinePointer;

    if (supportsHover) {
      var hideTimeout = null;
      var HIDE_DELAY = 150; /* ms delay before hiding popover */
      var currentPopover = null;

      document.querySelectorAll('button[popovertarget]').forEach(function(button) {
        var targetId = button.getAttribute('popovertarget');
        var popover = document.getElementById(targetId);
        if (!popover) return;

        /* Prevent default click from toggling popover */
        button.addEventListener('click', function(e) {
          e.preventDefault();
        });

        /* Show on button hover */
        button.addEventListener('mouseenter', function() {
          clearTimeout(hideTimeout);
          /* Hide any other open popover */
          if (currentPopover && currentPopover !== popover) {
            currentPopover.hidePopover();
          }
          popover.showPopover();
          currentPopover = popover;
        });

        /* Start hide timer when leaving button */
        button.addEventListener('mouseleave', function() {
          hideTimeout = setTimeout(function() {
            popover.hidePopover();
            if (currentPopover === popover) currentPopover = null;
          }, HIDE_DELAY);
        });

        /* Cancel hide when entering popover */
        popover.addEventListener('mouseenter', function() {
          clearTimeout(hideTimeout);
        });

        /* Hide when leaving popover */
        popover.addEventListener('mouseleave', function() {
          hideTimeout = setTimeout(function() {
            popover.hidePopover();
            if (currentPopover === popover) currentPopover = null;
          }, HIDE_DELAY);
        });
      });
    }
  }
});

function displayEXIFData(exifData, ul) {
    ul.innerHTML = '';

    if (!exifData || Object.keys(exifData).length === 0) {
        return;
    }

    /* Common EXIF tags people usually want to see */
    /* exifr uses slightly different tag names: ISO instead of ISOSpeedRatings */
    var priorityTags = [
        { key: 'Make', label: 'Make' },
        { key: 'Model', label: 'Model' },
        { key: 'DateTimeOriginal', label: 'DateTimeOriginal' },
        { key: 'ExposureTime', label: 'ExposureTime' },
        { key: 'FNumber', label: 'FNumber' },
        { key: 'ISO', label: 'ISOSpeedRatings' },
        { key: 'FocalLength', label: 'FocalLength' }
    ];

    /* Display priority tags */
    priorityTags.forEach(function(tag) {
        var v = exifData[tag.key];
        if (v !== undefined && v !== null && v.toString() !== 'NaN') {
            addExifItem(ul, tag.label, formatExifValue(tag.label, v));
        }
    });
}

/* Fetch EXIF data using exifr library */
/* We fetch the image data ourselves to avoid exifr's Node.js code paths */
async function fetchExifData(jpgUrl) {
    try {
        /* Check if exifr is loaded (may be delayed due to ES module import) */
        if (!window.exifr) {
            console.warn('exifr not loaded yet');
            return null;
        }
        
        /* Fetch only the first 64KB of the image (EXIF is always at the start) */
        /* This uses browser's fetch API which properly handles HTTP cache */
        var response = await fetch(jpgUrl, {
            headers: { 'Range': 'bytes=0-16383' }
        });
        
        /* Handle both full response (200) and partial content (206) */
        if (!response.ok && response.status !== 206) {
            throw new Error('Failed to fetch image: ' + response.status);
        }
        
        var buffer = await response.arrayBuffer();
        
        /* Parse EXIF from the ArrayBuffer - this uses browser-only code path */
        var exifData = await window.exifr.parse(buffer);
        return exifData;
    } catch (err) {
        console.warn('EXIF fetch failed:', err);
        return null;
    }
}

/* Get JPG path from image element (handles both <img> and <picture> cases) */
function getJpgPath(img) {
    var src = img.getAttribute('src') || '';
    /* If src is already a JPG, use it directly */
    if (src.toLowerCase().endsWith('.jpg') || src.toLowerCase().endsWith('.jpeg')) {
        return src;
    }
    /* For AVIF sources displayed via <picture>, construct JPG path */
    /* Replace .avif extension with .jpg, or append .jpg to basename */
    if (src.toLowerCase().endsWith('.avif')) {
        return src.replace(/\.avif$/i, '.jpg');
    }
    /* Fallback: try to construct JPG path from any extension */
    var lastDot = src.lastIndexOf('.');
    if (lastDot > 0) {
        return src.substring(0, lastDot) + '.jpg';
    }
    return src;
}

function addExifItem(ul, tag, value) {
    var li = document.createElement('li');
    li.setAttribute("tag", tag);
    li.setAttribute("description", formatTagName(tag));
    li.textContent = value;
    ul.appendChild(li);
}

function formatTagName(tag) {
    return tag
        .replace(/([A-Z])/g, '$1')
        .replace(/^./, function(str) { return str.toUpperCase(); });
}

function formatExifValue(tag, value) {
    if (tag === 'ExposureTime') {
        /* Convert to fraction for exposure time */
        if (value < 1) {
            return '1/' + Math.round(1/value) + 's';
        }
        return value + ' sec';
    } else if (tag === 'FNumber') {
        return 'f/' + value;
    } else if (tag === 'FocalLength') {
        return value + 'mm';
    } else if (Array.isArray(value)) {
        return value.join(', ');
    }
    return value;
}

/* Reveal a slide's nav arrows once its image can be laid out */
/* (the arrows are hidden until then - see .nav-arrow styles) */
function armSlideImageReady(img) {
  var itemDiv = img.closest('.lightbox-container');
  if (!itemDiv || itemDiv.classList.contains('img-ready')) return;

  /* Already loaded (e.g. cached): reveal immediately */
  if (img.complete && img.naturalWidth > 0) {
    itemDiv.classList.add('img-ready');
    return;
  }

  /* Otherwise wait for the image to load (or fail), once */
  if (itemDiv.dataset.imgReadyArmed) return;
  itemDiv.dataset.imgReadyArmed = 'true';
  var markImageReady = function() { itemDiv.classList.add('img-ready'); };
  img.addEventListener('load', markImageReady, { once: true });
  img.addEventListener('error', markImageReady, { once: true });
}

/* Handle hash change to load EXIF data for visible lightbox images */
/* Uses async/await to ensure non-blocking behavior */
async function handleHashChange() {
  var currentHash = window.location.hash.substring(1);
  if (!currentHash) return;

  var targetElement = document.getElementById(currentHash);
  if (!targetElement) return;

  var images = targetElement.querySelectorAll('.lightbox-container img');

  /* Reveal the nav arrows only once the slide's image is ready to lay out */
  images.forEach(armSlideImageReady);
  
  /* Process each image asynchronously without blocking rendering */
  images.forEach(function(img) {
    var itemDiv = img.closest('.lightbox-container');

    var exifDataElement = itemDiv.querySelector('.exif-data');
    if (!exifDataElement) {
      exifDataElement = document.createElement('ul');
      exifDataElement.className = 'exif-data';
      itemDiv.appendChild(exifDataElement);
    }

    /* Skip if EXIF already loaded for this image */
    if (itemDiv.dataset.exifLoaded) return;
    itemDiv.dataset.exifLoaded = 'true';

    /* Get JPG path for EXIF reading (works with both old JPGs and new AVIF+JPG setup) */
    var jpgPath = getJpgPath(img);

    /* Fetch EXIF data asynchronously - does not block rendering */
    /* Using requestIdleCallback for lowest priority, falls back to setTimeout */
    var scheduleExifLoad = window.requestIdleCallback || function(cb) { setTimeout(cb, 0); };
    
    scheduleExifLoad(async function() {
      var exifData = await fetchExifData(jpgPath);
      displayEXIFData(exifData, exifDataElement);
    });
  });
}

/* Initialize on page load and hash changes */
/* Use requestIdleCallback to avoid blocking initial render */
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', function() {
    var scheduleInit = window.requestIdleCallback || function(cb) { setTimeout(cb, 0); };
    scheduleInit(handleHashChange);
  });
} else {
  var scheduleInit = window.requestIdleCallback || function(cb) { setTimeout(cb, 0); };
  scheduleInit(handleHashChange);
}
window.addEventListener('hashchange', handleHashChange);

/* ========================================
   Progressive per-location loading (PT16/PT20)
   ======================================== */

/* The index and the year pages prerender the first N locations of their scope */
/* (site.prerender_locations); this loader appends the remaining location pages */
/* in order as the reader scrolls, rewiring the prev/next chain across batch */
/* boundaries. Without JavaScript the link list stays as plain navigation. */
(function() {
  var linksNav = document.querySelector('.location-links');
  var gallery = document.querySelector('main.gallery');
  if (!linksNav || !gallery) return;

  var links = Array.prototype.slice.call(linksNav.querySelectorAll('a[data-year][data-loc]'));
  if (links.length === 0) return;

  var BATCH = 5;
  var cursor = 0;
  var loading = false;
  var lastSlideId = null;
  var loadedKeys = {};

  function locKey(el) {
    return el.getAttribute('data-year') + '-' + el.getAttribute('data-loc');
  }

  /* mark the prerendered locations as loaded */
  document.querySelectorAll('main.gallery > .year > .location').forEach(function(sec) {
    var parts = (sec.getAttribute('id') || '').split('-');
    if (parts.length >= 3) loadedKeys[parts[1] + '-' + parts[2]] = true;
  });
  var renderedFigs = gallery.querySelectorAll('figure.lightbox-container');
  if (renderedFigs.length) lastSlideId = renderedFigs[renderedFigs.length - 1].id;

  function firstUnloadedIndex() {
    while (cursor < links.length && loadedKeys[locKey(links[cursor])]) cursor++;
    return cursor;
  }

  /* inject one fetched location page; keeps the global arrow chain intact */
  function injectLocation(doc) {
    var srcYear = doc.querySelector('main.gallery > .year');
    if (!srcYear) return;
    var srcLoc = srcYear.querySelector('section.location');
    if (!srcLoc) return;

    var yearName = srcYear.getAttribute('year');
    var targetYear = gallery.querySelector('section.year[year="' + yearName + '"]');
    var scope;
    if (targetYear) {
      targetYear.appendChild(srcLoc);
      scope = srcLoc;
    } else {
      gallery.appendChild(srcYear);
      scope = srcYear;
    }

    var figs = scope.querySelectorAll('figure.lightbox-container');
    if (figs.length === 0) return;

    /* previous location's last slide now continues into this location */
    if (lastSlideId) {
      var prevFig = document.getElementById(lastSlideId);
      var prevNext = prevFig ? prevFig.querySelector('.nav-next') : null;
      if (prevFig && !prevNext) {
        prevNext = document.createElement('a');
        prevNext.className = 'nav-next';
        prevNext.setAttribute('aria-label', 'Next');
        prevNext.textContent = '\u276f';
        prevFig.appendChild(prevNext);
      }
      if (prevNext) prevNext.setAttribute('href', '#' + figs[0].id);
      figs[0].querySelector('.nav-prev').setAttribute('href', '#' + lastSlideId);
    }
    lastSlideId = figs[figs.length - 1].id;
  }

  function prefetchNextBatch() {
    links.slice(cursor, cursor + BATCH).forEach(function(link) {
      var pre = document.createElement('link');
      pre.rel = 'prefetch';
      pre.href = link.href;
      document.head.appendChild(pre);
    });
  }

  function injectBatch() {
    if (loading) return;
    var start = firstUnloadedIndex();
    if (start >= links.length) return;

    loading = true;
    var batch = links.slice(start, start + BATCH);
    var chain = Promise.resolve();
    batch.forEach(function(link) {
      chain = chain.then(function() {
        return fetch(link.href, { credentials: 'same-origin' })
          .then(function(response) {
            if (!response.ok) throw new Error('fetch failed: ' + response.status);
            return response.text();
          })
          .then(function(html) {
            injectLocation(new DOMParser().parseFromString(html, 'text/html'));
            loadedKeys[locKey(link)] = true;
            cursor = Math.max(cursor, links.indexOf(link) + 1);
          });
      });
    });

    chain.then(function() {
      loading = false;
      if (window.refreshJourneyMaps) window.refreshJourneyMaps();
      if (window.observeLocationItems) window.observeLocationItems(gallery);
      prefetchNextBatch();
      /* if the sentinel is still close, keep going */
      if (linksNav.getBoundingClientRect().top < window.innerHeight * 2.5) injectBatch();
    }).catch(function() {
      loading = false; /* keep the links as fallback; the observer retries on the next scroll */
    });
  }

  var sentinelObserver = new IntersectionObserver(function(entries) {
    entries.forEach(function(entry) {
      if (entry.isIntersecting) injectBatch();
    });
  }, { rootMargin: '200% 0px' });
  sentinelObserver.observe(linksNav);

  /* deep links to a photo that is not prerendered: land on its location page */
  (function handleDeepLink() {
    var hash = location.hash;
    if (!hash || hash === '#p' || hash.length < 4) return;
    if (document.getElementById(hash.slice(1))) return;
    var m = /^#p-(\d{2})-(\d+)-/.exec(hash);
    if (!m) return;
    var key = m[1] + '-' + m[2];
    for (var i = 0; i < links.length; i++) {
      if (locKey(links[i]) === key) {
        location.replace(links[i].href + hash);
        return;
      }
    }
  })();
})();
