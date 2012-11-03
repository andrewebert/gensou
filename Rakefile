css_depends = FileList["public/less/*.less"]
css_targets = css_depends.collect { |c| 
    "../deploy/#{c.gsub("less", "css")}"
}

haml = "views/play.haml"
haml_target = "../deploy/#{haml}"

task :default => [:build] do
end

task :heroku => :build do
    sh "cd ../deploy && git add * && git commit -m 'deploy' && bundle && git push heroku master"
end

task :ai => :build do
    sh "rm ../deploy/Gemfile.lock"
    sh "sftp -b ai.batch ai_zakharov:violentllamafarmer@1.ai"
end

task :build => [haml_target, css_targets] do
end

task :copy do
    sh "cp -rp * ../deploy"
end

css_depends.zip(css_targets).each do |depend, target|
    file target => [depend] do |t|
        sh "lessc #{depend} > #{target}"
    end
end

file haml_target => [haml, :copy] do
    # Replace references to .less with .css; remove include of less.js
    sh "grep -v -e 'js/less\\.js.' -e 'stylesheet/less' -e 'js/jquery\\.js' #{haml} | sed 's/\\(.*\\)\\/\\/\\/\\(.*\\)/\\1\\2/' > #{haml_target}"
end
