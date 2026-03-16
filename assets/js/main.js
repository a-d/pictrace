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

/* Process journey progress data stored by inline scripts */
/* Inline scripts store coordinate arrays in window.journeyProgressData */
/* This runs after main.js loads and creates the actual progress functions */
if (window.journeyProgressData) {
  Object.keys(window.journeyProgressData).forEach(function(name) {
    window[name] = makeProgressMapper(window.journeyProgressData[name]);
  });
}

(function() {
  /* Only define once */
  if (window.journeyMapInitialized) return;
  window.journeyMapInitialized = true;

  /* Default linear progress (can be overridden per journey) */
  var defaultProgress = function(t) { return t; };

  /* Check if CSS scroll-driven animations are supported */
  var supportsScrollTimeline = CSS.supports('animation-timeline', 'view()');

  var maps = [];

  /* Initialize all journey maps - runs for ALL browsers */
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
        pathLength: 0,
        count: parseInt(mapElement.getAttribute('count'), 10) || 10,
        progressFn: progressFn
      };

      /* Only set up path animation for fallback browsers */
      if (!supportsScrollTimeline && path) {
        mapData.pathLength = path.getTotalLength();
        path.style.strokeDasharray = mapData.pathLength;
        path.style.strokeDashoffset = mapData.pathLength;
      }

      maps.push(mapData);
    });
  }

  /* Update grid layout - runs for ALL browsers */
  function updateGridLayout() {
    var gallery = document.querySelector('.gallery');
    var columns = gallery ? getComputedStyle(gallery).gridTemplateColumns.split(' ').length - 1 : 1;
    maps.forEach(function(map) {
      map.element.style.gridRow = 'span ' + Math.ceil(map.count / columns);
    });
  }

  /* Update path animation - only for fallback browsers */
  function updatePathAnimation() {
    if (supportsScrollTimeline) return;

    var windowHeight = window.innerHeight;
    maps.forEach(function(map) {
      if (!map.path || !map.pathLength) return;

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

  /* Initialize on DOM ready and handle dynamic content */
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function() {
      initJourneyMaps();
      updateGridLayout();
      updatePathAnimation();
    });
  } else {
    initJourneyMaps();
    updateGridLayout();
    updatePathAnimation();
  }

  /* Event listeners */
  window.addEventListener('scroll', updatePathAnimation); /* Only path animation on scroll */
  window.addEventListener('resize', function() {
    initJourneyMaps();
    updateGridLayout();
    updatePathAnimation();
  });
})();

/* ========================================
   Gallery and EXIF functionality
   ======================================== */

document.addEventListener('DOMContentLoaded', function() {
  /* close spot popover when clicking location/year links */
  {
    var sel = document.getElementById('spot');
    if (sel) {
      sel.querySelectorAll('a[href^="#"]').forEach(function(n) {
        n.addEventListener('click', function(e) {
          sel.hidePopover();
        });
      });
    }
  }

  /* add location scrolling indicator */
  {
    var locationIndicator = document.getElementById("location-indicator");
    var locationItems = document.querySelectorAll(".gallery .gallery-item");
    if (locationIndicator && locationItems.length > 0) {
      var locationObserver = new IntersectionObserver(function(entries) {
        entries.forEach(function(entry) {
          if (entry.isIntersecting) {
            locationIndicator.style.opacity = 1;
            locationIndicator.textContent = entry.target.getAttribute("location");
          }
        });
      }, { threshold: 1 }); /* 100% visible */
      locationItems.forEach(function(sec) { locationObserver.observe(sec); });

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
    document.querySelectorAll('.gallery-item > a.image').forEach(function(link) {
      link.addEventListener('click', function(event) {
        closeLink.setAttribute('href', window.location.hash || '#p');
      });
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

/* Handle hash change to load EXIF data for visible lightbox images */
/* Uses async/await to ensure non-blocking behavior */
async function handleHashChange() {
  var currentHash = window.location.hash.substring(1);
  if (!currentHash) return;

  var targetElement = document.getElementById(currentHash);
  if (!targetElement) return;

  var images = targetElement.querySelectorAll('.lightbox-container img');
  
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
