'use strict';

var gulp = require('gulp');
var imageResize = require('gulp-image-resize');
var rename = require('gulp-rename');
var del = require('del');
var prompt = require('gulp-prompt');

// Variables to store user inputs
let year = '';
let location = '';
let shouldDelete = false;

function getIndexedLocation(year, location) {
  const yearDir = `images/${year}`;

  // Create year directory if it doesn't exist
  const fs = require('fs');
  const path = require('path');
  if (!fs.existsSync(yearDir)) {
    fs.mkdirSync(yearDir, { recursive: true });
    return `01_${location}`; // First location in a new year
  }

  // Read existing directories to find location indices
  const existingDirs = fs.readdirSync(yearDir).filter(dir =>
    fs.statSync(path.join(yearDir, dir)).isDirectory()
  );

  // Check if this location already exists (with any index)
  const existingLocation = existingDirs.find(dir => {
    // Extract location name by removing the index prefix (e.g., "01_Berlin" -> "Berlin")
    const locationName = dir.replace(/^\d+_/, '');
    return locationName === location;
  });

  if (existingLocation) {
    console.log(`Found existing location: ${existingLocation}`);
    return existingLocation; // Reuse existing indexed location
  }

  // Find the highest index currently in use
  let highestIndex = 0;
  existingDirs.forEach(dir => {
    const match = dir.match(/^(\d+)_/);
    if (match) {
      const index = parseInt(match[1], 10);
      highestIndex = Math.max(highestIndex, index);
    }
  });

  // Use the next available index
  const nextIndex = highestIndex + 1;
  console.log(`Inferred next index: ${nextIndex}`);
  return `${String(nextIndex).padStart(2, '0')}_${location}`;
}

// Task to get user inputs
gulp.task('get-inputs', function() {
  return gulp.src('./package.json')
    .pipe(prompt.prompt([
      {
        type: 'input',
        name: 'year',
        message: 'Enter the year:'
      },
      {
        type: 'input',
        name: 'location',
        message: 'Enter the location:'
      },
      {
        type: 'confirm',
        name: 'shouldDelete',
        message: 'Do you want to delete original images after resizing?',
        default: false
      }
    ], function(res) {
      year = res.year;
      location = res.location;
      shouldDelete = res.shouldDelete;

      // Create directories if they don't exist
      const fs = require('fs');
      const path = require('path');
      const dir = getIndexedLocation(year, location);

      const fullsDir = `images/${year}/${dir}/fulls`;
      const thumbsDir = `images/${year}/${dir}/thumbs`;

      if (!fs.existsSync(fullsDir)) {
        fs.mkdirSync(fullsDir, { recursive: true });
      }

      if (!fs.existsSync(thumbsDir)) {
        fs.mkdirSync(thumbsDir, { recursive: true });
      }
    }));
});

gulp.task('delete', function() {
  if (shouldDelete) {
    return del(['images/*.*']);
  } else {
    console.log('Delete task skipped');
    return Promise.resolve();
  }
});

gulp.task('resize-images', function() {
  const dir = getIndexedLocation(year, location);
  return gulp.src('images/*.*')
    .pipe(imageResize({
      width: 1024,
      imageMagick: true
    }))
    .pipe(gulp.dest(`images/${year}/${dir}/fulls`))
    .pipe(imageResize({
      width: 512,
      imageMagick: true
    }))
    .pipe(gulp.dest(`images/${year}/${dir}/thumbs`));
});

// resize images with user inputs first
gulp.task('resize', gulp.series('get-inputs', 'resize-images', 'delete'));

// default task
gulp.task('default', gulp.series('resize'));
