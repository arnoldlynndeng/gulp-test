gulp = require 'gulp'
pngquant = require('imagemin-pngquant')
plugins = require('gulp-load-plugins')()

dest_dir = 'dest/public/'
build_dir = 'build/public/'

#错误处理
handleError = (err)->
  plugins.util.beep()
  plugins.util.log err.toString()
LessPluginAutoPrefix = require 'less-plugin-autoprefix'
autoprefix = new LessPluginAutoPrefix(browsers: [
  "ie >= 8"
  "ie_mob >= 10"
  "ff >= 26"
  "chrome >= 30"
  "safari >= 6"
  "opera >= 23"
  "ios >= 5"
  "android >= 2.3"
  "bb >= 10"
])

clean_src = 'dest/public'
gulp.task 'clean', ()->
  gulp.src clean_src
    .pipe plugins.clean()

coffee_dest = 'dest/public/js'
coffee_src = 'src/coffee/**/*.coffee'
gulp.task 'coffee', ()->
  gulp.src coffee_src
    .pipe plugins.plumber(errorHander: handleError)
    #只编译修改过的文件
    .pipe plugins.changed(coffee_dest, extension: '.js')
    .pipe plugins.coffee()
    .pipe gulp.dest coffee_dest
    .pipe plugins.notify({message: 'coffee task complete'})
less_dest = 'dest/public/css'
less_src = 'src/less/**/*.less'
gulp.task 'less', ()->
  
  gulp.src less_src
    .pipe plugins.plumber(errorHander: handleError)
    .pipe plugins.changed(less_dest, extension: '.css')
    .pipe plugins.less(
      plugins: [autoprefix]
    )
    .pipe gulp.dest(less_dest)
    .pipe plugins.notify({message: 'less task complete'})
jade_dest = 'dest/public/'
jade_src = 'src/jade/**/*.jade'
gulp.task 'jade', ()->
  
  gulp.src jade_src
    .pipe plugins.plumber(errorHander: handleError)
    .pipe plugins.changed(jade_dest, extension: '.html')
    .pipe plugins.jade({ pretty: true})
    .pipe gulp.dest(jade_dest)
    .pipe plugins.notify({message: 'jade task complete'})
copy_dest = 'dest/public/'
copy_src = 'src/**/*'
gulp.task 'copy', ()->
  copyFilter = plugins.filter [
    'fonts/**/*'
    'images/**/*'
    'lib/**/*'
  ]
  imageFilter = plugins.filter 'images/**/*', {restore: true}
  gulp.src copy_src
    .pipe plugins.plumber(errorHander: handleError)
    .pipe plugins.changed(copy_dest)
    .pipe imageFilter
    .pipe plugins.imagemin(
      {
        progressive: true
        svgoPlugins: [{removeViewBox: false}]
        use: [pngquant({ quality: '65-80', speed: 4 })]
      }
    )
    .pipe imageFilter.restore
    .pipe copyFilter
    .pipe gulp.dest(copy_dest)
    .pipe plugins.notify({message: 'copy task complete'})
# 解析html中build:{type}块，将里面引用到的文件合并传过来
index_dest = 'dest/public/'
index_src = 'dest/public/**/*.html'
gulp.task 'index',['jade', 'coffee', 'less', 'copy'], ()->
  jsFilter = plugins.filter '**/*.js', {restore: true}
  cssFilter = plugins.filter '**/*.css', {restore: true}
  userefAssets = plugins.useref.assets()
  gulp.src index_src
    .pipe userefAssets
    .pipe jsFilter
    .pipe(plugins.rename({suffix: '.min'}))
    .pipe plugins.uglify()
    .pipe jsFilter.restore
    .pipe cssFilter
    .pipe(plugins.rename({suffix: '.min'}))
    .pipe plugins.csso()
    .pipe cssFilter.restore
    .pipe userefAssets.restore()
    .pipe plugins.useref()
    .pipe gulp.dest index_dest
    .pipe plugins.notify({message: 'index task complete'})


gulp.task 'rest', ['clean'], ()->
  gulp.start 'jade', 'coffee', 'less', 'copy'
public_src = 'dest/public/**/*'
public_dest = 'dest/public'    
gulp.task 'rev', ['index'], ()->
  revFilter = plugins.filter [
    'static/*'
    'fonts/**/*'
    'images/**/*'
  ], {restore: true}
  gulp.src public_src
    .pipe plugins.plumber(errorHander: handleError)
    .pipe revFilter
    .pipe plugins.rev()
    .pipe plugins.revCssUrl() #重写css 文件对应文件版本
    .pipe gulp.dest public_dest
    .pipe plugins.rev.manifest({merge:true})
    .pipe gulp.dest public_dest
    .pipe revFilter.restore
    .pipe plugins.notify({message: 'rev task complete'})
gulp.task 'replace', ['rev'], ()->
  mainfest = gulp.src "./#{public_dest}/rev-manifest.json"
  gulp.src index_src
    .pipe plugins.revReplace({manifest: mainfest})
    .pipe gulp.dest public_dest
    .pipe plugins.notify({message: 'replace task complete'})
gulp.task 'build', ['clean'], ()->
  gulp.run 'replace'

gulp.task 'w', ()-> 
  gulp.watch [coffee_src, jade_src, less_src, copy_src], ['coffee', 'jade', 'less', 'copy']
  server = plugins.livereload()

  gulp.watch([public_src]).on 'change', (file)->
    server.changed(file.path)

