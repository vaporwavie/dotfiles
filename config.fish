# No mo' greetings
set fish_greeting

starship init fish | source

function ll
	ls -l $argv	
end

function l
	ls -lah $argv
end


alias dockis="sudo systemctl start docker && sudo docker run --name redis -p 6379:6379 -d redis"

alias cat="bat"
alias oni="/usr/bin/Oni2"
alias nuke="sudo shutdown -h now"
