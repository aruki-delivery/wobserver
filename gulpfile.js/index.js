const config     = require('./config');
const gulp       = require('gulp');
const requireDir = require('require-dir');

requireDir('./tasks', { recurse: false });

gulp.task('build', config.build);
gulp.task('deploy', config.deploy);
gulp.task('default', ['build', 'watch']);
