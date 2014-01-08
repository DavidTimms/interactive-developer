if require?
	coffee = require "coffee-script"
	fs = require "fs"

outputBox = $("#output")
consoleBox = $("#console")

animSpeed = 80

lang = "javascript"
compile = 
	javascript: (source) -> source

if coffee?
	compile.coffeescript = (source) -> 
		coffee.compile(source, {bare: true})
	lang = "coffeescript"

window.pg = 
	setLang: (newLang) ->
		newLang = newLang.toLowerCase()
		if newLang of compile
			lang = newLang
			"now using #{lang}"
		else
			throw new Error("#{newLang} is not a supported language")

	say: (message) -> 
		printResult(message, "user")
		return

	show: (filename) -> 
		fs.readFile filename, 'utf8', (err, content) ->
			if err then throw err
			if filename.toLowerCase().split(".").pop() in ["md", "markdown", "mdown"]
				content = require("marked")(content)
			printUnescaped(content, "user")
		return

	ls: -> fs.readdirSync(".").join("\n")
	cwd: process.cwd
	cd: (path) -> 
		process.chdir(path)
		process.cwd()

	exec: (command) ->
		child = require("child_process").exec(command)
		child.stdout.on "data", (output) ->
			printResult output.toString()
		child.stderr.on "data", (output) ->
			printResult output.toString(), 'error'
		return

	import: (funcName) ->
		if funcName not of pg
			throw "#{funcName} is not a valid playground function"
		window[funcName] = pg[funcName]
		"imported #{funcName} to global namespace"

explanations =
	ls: "list all files and directories in the current working directory"
	cwd: "print the current directory"
	cd: "change the current working directory"
	exec: "execute a system command"
	show: "display the contents of a file (renders html/markdown)"
	egsg: "error"

for exp of explanations
	do (exp) -> pg[exp]?.toString = -> explanations[exp]

addOutputNode = (node) ->
	node.appendTo(outputBox).hide().fadeIn(animSpeed)
	(doc = $(document)).scrollTop(doc.height())

printBlock = (code) -> 
	innerBox = $("<code></code>").addClass("language-#{lang}").text(code)
	addOutputNode $("<pre class='out-block'></pre>").append(innerBox)

	Prism.highlightElement(innerBox[0])

msgColors =
	user: "navy"
	error: "maroon"
	success: "darkgreen"
	default: "darkgreen"

printResult = (result, msgType) -> 
	color = msgColors[msgType] || msgColors.default
	resStr = result?.toString()
	if resStr.match(/\[object/)
		try 
			resStr = JSON.stringify(result)
		catch e
			resStr
	addOutputNode $("<pre class='result-block'></pre>").text(resStr).css({color: color})

printUnescaped = (output, msgType) -> 
	addOutputNode $("<pre class='result-block unescaped'></pre>").html(output)

consoleBox.on "keydown", (e) ->
	source = consoleBox.val().trim()
	if e.keyCode == 13 && not e.shiftKey && source != ""
		e.preventDefault()
		consoleBox.val("")
		printBlock source
		try
			source = compile[lang](source)
			res = eval.call(window, source)
			if res != undefined
				printResult res
		catch err
			printResult err, "error"

outputBox.on "click", ".out-block", (e) ->
	consoleBox.focus().val($(this).text())

process?.on "uncaughtException", (err) ->
	printResult err, "error"