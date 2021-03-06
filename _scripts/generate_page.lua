#!/usr/bin/lua

markdown = require('discount')
lyaml = require('lyaml')
lustache = require('lustache')

function read_markdown(file)
	local f = assert(io.open(file))
	local data = f:read("*a")
	f:close()
	local yml, md = data:match("^(%-%-%-.-%-%-%-)(.*)$")
	local t
	local pagename = file:gsub(".md$","")
	local pageclass = pagename:gsub("/.*", "")
	if yml and md then
		t = lyaml.load(yml)
		t.pagename = pagename
		t.pageclass = pageclass
		return t, markdown(md)
	else
		return {title=pagename:gsub("/index$", ""), pagename=pagename,
			pageclass=pageclass}, markdown(data)
	end
end

function read_layout(file)
	-- try look for template for 'path/file.md' in this order:
	--   path/file.template.html
	--   layout.template.html
	for _,t in pairs{file:gsub(".md$", ".template.html"),
		"_default.template.html"} do
		local f = io.open(t)
		if f then
			local data = f:read("*a")
			f:close()
			return data
		end
	end
end

function ref_class(pagename, href)
	local refpage = href:gsub(".html$", "")
	refpage = refpage:gsub("/$", "/index")
	if refpage:match("^/?"..pagename.."$") then
		return ' class="active"'
	end
	return ''
end

function import_yaml(filename)
	local f = assert(io.open(filename))
	local t = lyaml.load(f:read("*a*"))
	f:close()
	return t
end

page, content = read_markdown(assert(arg[1]))
layout = read_layout(arg[1])
for i = 2, #arg do
	local t = {}
	for k,v in pairs(import_yaml(arg[i])) do
		t[k] = v
	end
	tname = string.gsub(arg[i], ".yaml$", "")
	page[tname] = t
end

page.pagestate = {}
page.pagestate[page.pagename] = 'active'

page.content = lustache:render(content, page)

if page.date then
	local y,m,d = page.date:match("(%d+)-(%d+)-(%d+)")
	page.pubdate = os.date("%b %d, %Y", os.time{year=y, month=m, day=d})
end

io.write(lustache:render(layout, page))
