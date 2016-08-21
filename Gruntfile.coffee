module.exports = (grunt) ->
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-haml'
  grunt.loadNpmTasks 'grunt-contrib-sass'
  grunt.loadNpmTasks 'grunt-newer'
  grunt.initConfig {
    pkg: grunt.file.readJSON('package.json'),
    watch: {
      haml: {
        files: ['**/*.haml']
        tasks: ['newer:haml', 'karma:unit:run']
      },
      coffee: {
        files: 'DungeonBuilder.coffee'
        tasks: ['coffee']
      }
      sass: {
        files: ['style.scss'],
        tasks: ['sass']
      }
    },
    coffee: {
      comile: {
        files: 'DungeonBuilder.js': 'DungeonBuilder.coffee'
      }
    },
    sass: {
      dist: {
        src: 'style.scss',
        dest: 'css/style.css'
      }
    },
    haml: {
      index: {
        src: 'index.html.haml',
        dest: 'index.html'
        options: {
          language: 'ruby'
        }
      },
    }
  }
  # grunt.registerTask 'build', ['coffee', 'sass', 'haml']
  grunt.registerTask 'build', ['coffee', 'sass']
  grunt.registerTask 'default', ['build', 'watch']
