(function() {
  // Check if CSS scroll-driven animations are supported
  const supportsScrollTimeline = CSS.supports('animation-timeline', 'view()');
  if (supportsScrollTimeline) {
    // Native support is available, so no JavaScript fallback is needed.
    return;
  }

  // Fallback for browsers without CSS scroll-driven animations.
  // This script will manage the animation for all map components on the page.

  // Use a more descriptive name for the progress mapping function.
  function createScrollProgressMapper(points) {
    // Ensure points are sorted by the first element (scroll percentage)
    points.sort((a, b) => a[0] - b[0]);

    return function(t) {
      if (t <= points[0][0]) return points[0][1];
      if (t >= points[points.length - 1][0]) return points[points.length - 1][1];

      // Find the segment where t falls
      let i = 1;
      while (i < points.length && t > points[i][0]) {
        i++;
      }

      // For Catmull-Rom, we need 4 points: p0, p1, p2, p3
      const p0 = points[Math.max(i - 2, 0)];
      const p1 = points[i - 1];
      const p2 = points[i];
      const p3 = points[Math.min(i + 1, points.length - 1)];

      // Normalize t to a [0, 1] range within the current segment
      const u = (t - p1[0]) / (p2[0] - p1[0]);

      // Calculate the interpolated value using a Catmull-Rom spline
      const y =
        0.5 *
        (
          (2 * p1[1]) +
          (-p0[1] + p2[1]) * u +
          (2 * p0[1] - 5 * p1[1] + 4 * p2[1] - p3[1]) * u * u +
          (-p0[1] + 3 * p1[1] - 3 * p2[1] + p3[1]) * u * u * u
        );

      // Clamp the output to the [0, 1] range to prevent over- or under-shooting
      return Math.min(1, Math.max(0, y));
    };
  }


  // A single, optimized function to handle updates for all maps
  function updateAllMaps() {
    const gallery = document.querySelector('.gallery');
    if (!gallery) return;

    const columns = getComputedStyle(gallery).gridTemplateColumns.split(' ').length;

    document.querySelectorAll('.map').forEach(mapElement => {
      // Set the grid row span dynamically based on the number of columns
      const imageCount = parseInt(mapElement.getAttribute('count'), 10) || 0;
      if (imageCount > 0 && columns > 0) {
        mapElement.style.gridRow = "span " + Math.ceil(imageCount / columns);
      }

      const path = mapElement.querySelector('.travel-path');
      if (!path) return;

      const pathLength = path.getTotalLength();
      if (pathLength === 0) return;

      // Set initial dash array and offset if not already set
      if (path.style.strokeDasharray === '') {
        path.style.strokeDasharray = pathLength;
        path.style.strokeDashoffset = pathLength;
      }

      // Calculate scroll progress relative to the map element's viewport visibility
      const rect = mapElement.getBoundingClientRect();
      const scrollPercent = Math.max(0, Math.min(1, (window.innerHeight - rect.top) / (window.innerHeight + rect.height)));

      // Apply the Catmull-Rom spline interpolation for smoother animation
      const mappedProgress = mapProgress(scrollPercent);
      const drawLength = pathLength * mappedProgress;
      path.style.strokeDashoffset = pathLength - drawLength;
    });
  }

  // Initialize all map components on the page
  function initializeMaps() {
    let mapCounter = 0;
    document.querySelectorAll('.map').forEach(mapElement => {
      const pathId = mapElement.getAttribute("pathId");
      if (pathId) {
        const path = mapElement.querySelector('#' + pathId);
        if (path) {
          // Ensure each path has a unique class for styling and a unique ID for selection
          path.classList.add('travel-path');
          mapCounter++;
        }
      }
    });

    updateAllMaps(); // Perform an initial update
  }

  // Define the progress mapping
  const mapProgress = createScrollProgressMapper([
    [0.0, 0.07],
    [0.4, 0.6],
    [0.7, 0.7],
    [0.9, 0.8],
    [1.0, 1.0]
  ]);

  // Add event listeners that call the single update function
  window.addEventListener('scroll', updateAllMaps, { passive: true });
  window.addEventListener('resize', updateAllMaps, { passive: true });

  // Initialize everything once the DOM is fully loaded
  document.addEventListener('DOMContentLoaded', initializeMaps);

})();
