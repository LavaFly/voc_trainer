#!/usr/bin/lua5.3
--[[

┌───────────────────────────────────┐
│            VOC Trainer            │
└───────────────────────────────────┘

]]--

--[[

  Possible Arguments to Script ( eg. voc_trainer.lua folder=this file=that mode=3 )
   folder=n    recommended from bottom up
   file=n,m,... 
   mode=1,2,3,i,1i,2i,3i
   audio(mode=1,2)(folder=n)(file=n,m,..)(speed=slow/medium/fast)(repeat=n/true) 
   play/pause/stop/help
   
  To choose options, either enter the associated number 
  or part of the option eg.: 
     [1]this_is_a_file
     [2]another_file
     [3]one_more_file
     [4]last_file
     
  '1' & 'this'  will both select the first option
  (only works while choosing a file or folder!)
  
  Audio-mode works kind of, I need to find an alternative to 'espeak' 
  as it's not sounding good in French though I haven't tested other languages
  
  TODO
  - Audio-mode
  - structorize code 
  - remove global variables
  
  
  - goto error handling   assert(type(in) == correct, error-message) pcall xpcall
  - show improvement of % after practise
  
]]--
-- 
require 'utf8'
math.randomseed(os.time())
math.random()
math.random()

-- main functions
function second_setup() -- funciton for each case, lookup table
  
  local answ = choose_option(first_options, "Choose Option:\n")
  if answ == 1 then
    folder_name = folder_name~="" and folder_name or choose_option("ls -d */", "Choose folder:\n")
    file_name = file_name~="" and file_name or choose_option("ls " .. folder_name .. " -tr | sed s'/.txt//'", "Choose file:\n")
    file_list[1] = file_list[1] and file_list[1] or file_name
    practise_mode = practise_mode~=0 and practise_mode or get_practise_mode()
    practise()
  elseif answ == 2 then
    answ = choose_option(file_options,"Choose Option:\n")
    if answ == 1 then
      folder_name = folder_name~="" and folder_name or choose_option("ls -d */", "Choose folder:\n")
      new_voc()
    elseif answ == 2 then
      folder_name = folder_name~="" and folder_name or choose_option("ls -d */", "Choose folder:\n")
      file_name = file_name~="" and file_name or choose_option("ls " .. folder_name .. " -tr | sed s'/.txt//'", "Choose file:\n")
      file_list[1] = file_list[1] and file_list[1] or file_name
      view_file()
    elseif answ == 3 then
      -- add remove file function !!
    elseif answ == 4 then
      complete_overview()
    else
      io.write("kk")
    end
  elseif answ == 3 then
    folder_name = folder_name~="" and folder_name or choose_option("ls -d */", "Choose folder:\n")
    score_overview()
  else
    io.write("idk what to do")
  end
end
function setup() 
  
  io.write(string.format("Choose Option:\n\t[1]Practise\n\t[2]Add Vocs\n\t[3]Show Scores\n\t[4]Show all Lessons\n\t[5]View File\n"))
  local answ = tonumber(io.read())
  io.write("\n")
  
  if answ == 1 then -- this is so ugly, but a lookup table wont work
    folder_name = folder_name~="" and folder_name or choose_option("ls -d */", "Choose folder:\n")
    file_name = file_name~="" and file_name or choose_option("ls " .. folder_name .. " -tr | sed s'/.txt//'", "Choose file:\n")
    file_list[1] = file_list[1] and file_list[1] or file_name
    practise_mode = practise_mode~=0 and practise_mode or get_practise_mode()
    practise()
  elseif answ == 2 then
    folder_name = folder_name~="" and folder_name or choose_option("ls -d */", "Choose folder:\n")
    new_voc()
  elseif answ == 3 then
    folder_name = folder_name~="" and folder_name or choose_option("ls -d */", "Choose folder:\n")
    score_overview()
  elseif answ == 4 then
    complete_overview()
  elseif answ == 5 then
    folder_name = folder_name~="" and folder_name or choose_option("ls -d */", "Choose folder:\n")
    file_name = file_name~="" and file_name or choose_option("ls " .. folder_name .. " -tr | sed s'/.txt//'", "Choose file:\n")
    file_list[1] = file_list[1] and file_list[1] or file_name
    view_file()
  else
    io.write("idk what to do")
  end
end
function practise()
  -- :: practise_start :: 
  for _=1,#file_list do
    local a = string.rep("─",16+#file_name)
    io.write(string.format("\n\n%s\nNow testing : %s\n%s\n",a,file_name,a))
    if practise_mode == 3 then 
      comp_practise()
      return
    end
    local vocs = {}
    local voc_file = io.input(folder_name .. file_name .. ".txt")
    local line_ctr,word_ctr,num_correct,result = 1,1,0,0
    local ans = ""
  
    for line in voc_file:lines() do
      vocs[line_ctr] = {}
      for word in line:gmatch("[^,?]*") do
        vocs[line_ctr][word_ctr] = word
        word_ctr = (word_ctr + 1) % 2
      end
      line_ctr = line_ctr + 1
    end
  
    voc_file:close()
    shuffle_array(vocs,line_ctr)
  
    for i = 1,line_ctr - 1,1 do
      io.write((practise_mode == 1 and (vocs[i][0] .. " in french: ") or (vocs[i][1] .. " in german: ")))
      answer = io.stdin:read()
      if answer == (practise_mode == 1 and (vocs[i][1]) or (vocs[i][0])) then
        io.write(" ->correct\n")
        num_correct = num_correct + 1
      else
        if get_hamming_distance(answer,(rnd == 1 and vocs[i][1] or vocs[i][0])) <= (#ans/4) then
          num_correct = num_correct + 0.5
        end
        io.write(" ->false " .. (practise_mode == 1 and (vocs[i][1]) or (vocs[i][0])) .. "\n")
      end
    end
    result = (num_correct / (line_ctr - 1)) * 100
    local best_score = tonumber(score_check(result))
    io.write(string.format("\n%d out of %d were correct(%3.2f%%)\n",num_correct,line_ctr - 1,result))
    io.write(string.format("\nBest Score : %3.2f%%\n",best_score))
    -- if(infinite_practise) then goto practise_start end
    next_file_from_list()
  end
end
function comp_practise()
  local vocs = {}
  local voc_file = io.input(folder_name .. file_name .. ".txt")
  local line_ctr,word_ctr,num_correct,result = 1,1,0,0
  local rnd, time_now = 0,0
  local ans = ""
  
  for line in voc_file:lines() do
    vocs[line_ctr] = {}
    for word in line:gmatch("[^,?]*") do
      vocs[line_ctr][word_ctr] = word
      word_ctr = (word_ctr + 1) % 2
    end
    line_ctr = line_ctr + 1
  end
  
  voc_file:close()
  shuffle_array(vocs, line_ctr)
    
  for i = 1, line_ctr - 1 do
    time_now = os.time()
    rnd = int_divide(math.random(), 0.5)
    io.write((rnd == 1 and (vocs[i][0] .. " in french: ") or (vocs[i][1] .. " in german: ")))
    answer = io.stdin:read()
    
    if answer == (rnd == 1 and vocs[i][1] or vocs[i][0]) then
      if os.difftime(os.time(), time_now) <= 5 then
        num_correct = num_correct + 1
      end
    elseif get_hamming_distance(answer,(rnd == 1 and vocs[i][1] or vocs[i][0])) <= (#ans/4) then
      num_correct = num_correct + 0.5
    end
    
    io.write( "\n" )
  end
  result = (num_correct / (line_ctr - 1)) * 100
  local best_score = tonumber(score_check(result))
  io.write(string.format("\n%d out of %d were correct(%3.2f%%)\n",num_correct,line_ctr - 1,result))
  io.write(string.format("\nBest Score : %3.2f%%\n",best_score))
end
function new_voc()
  --[[
    Valid Input examples:
      hello bonjour
      hello,bonjour
      hello, bonjour
      hello  bonjour
      I am  Je suis
      I am,Je suis
      I am, Je suis
  ]]--
  
  io.write("Name File(if existing, will append):")
  file_name = io.read()
  score_check(file_name,0.0,1)
  local buffer = ""
  io.write("Write 'exit' to end\n")
  repeat
    buffer = buffer .. parse_new_vocs(trim(io.stdin:read())) .. "\n"
  until(buffer:match("exit"))
  local new_vocs = io.open(folder_name .. file_name .. ".txt", "a+")
  new_vocs:write(buffer:sub(0,utf8.len(buffer)-5)) -- cutting out the "exit"
  new_vocs:close()
end
function score_overview() 
  local score_file = io.input(folder_name .. "Score.txt")
  local score_table,tmp_scores = {},{0,0,0}
  local longest_name,key = 0,""
  
  for line in score_file:lines() do
    key = line:match("%a+")
    longest_name = (#key > longest_name) and (#key) or (longest_name) 
    score_table[key] = line:match("%d+.%d+ : %d+.%d+ : %d+.%d+")
  end
  
  score_file:close()
  
  local top_frame = "┌" .. string.rep("─",longest_name+2) .. "┬" .. string.rep("─",10) .. "┬" .. string.rep("─",10) .. "┬" .. string.rep("─",10) .. "┐\n"
  local top_frame2 = "├" .. string.rep("─",longest_name+2) .. "┼" .. string.rep("─",10) .. "┼" .. string.rep("─",10) .. "┼" .. string.rep("─",10) .. "┤\n"
  local header = string.format("│ %s│ %-9s│ %-9s│ %-9s│\n",variable_padding("FileName",longest_name+1),"F->G","G->F","Hardcore")
  local bottom_frame = "└" .. string.rep("─",longest_name+2) .. "┴" .. string.rep("─",10) .. "┴" .. string.rep("─",10) .. "┴" .. string.rep("─",10) .. "┘\n"
  
  io.write(top_frame)
  io.write(header)
  io.write(top_frame2)
  
  for key,value in sorted_iterator(score_table,function (unsorted_table,a,b) return avg(unsorted_table[b]) < avg(unsorted_table[a]) end) do
    local a,b,c = value:match("(%d+.%d+) : (%d+.%d+) : (%d+.%d+)")
    io.write(string.format("│ %s │ %s │ %s │ %s │\n",variable_padding(key,longest_name),color_padding(a),color_padding(b),color_padding(c)))
  end
  
  io.write(bottom_frame)
end
function complete_overview() -- cleanup output
  -- lists folder with files
  local folder_list = io.popen("ls -d */")
  
  for line in folder_list:lines() do
    local file_list = assert(io.popen(string.format("ls %s -tr",line)))
    io.write("├" .. line .. "\n")
      for file_lines in file_list:lines() do
        io.write("├──" .. file_lines .. "\n")
      end
    file_list:close()
  end
  folder_list:close()
end
function get_practise_mode()
  io.write("Choose mode:\n\t[1]German -> French\n\t[2]French -> German\n\t[3]Hardcore\n\t[i]Infinite\n")
  return tonumber(io.read())
end
function view_file()
  local vocs = {}
  local voc_file = io.input(folder_name .. file_name .. ".txt")
  local line_ctr,word_ctr,longest_word = 1,0,0
  local ans = ""
  
  for line in voc_file:lines() do
    vocs[line_ctr] = {}
    for word in line:gmatch("[^,?]*") do
      vocs[line_ctr][word_ctr] = word
      longest_word = math.max(longest_word,#word)
      word_ctr = (word_ctr + 1) % 2
    end
    line_ctr = line_ctr + 1
  end
  
  voc_file:close()
  local header = string.format("┌%s┐\n│ %s │\n├%s┬%s┤\n",string.rep("─",2 * longest_word + 5),variable_padding(file_name,longest_word * 2 + 3),string.rep("─",longest_word + 2),string.rep("─",longest_word + 2))
  local bottom = string.format("└%s┴%s┘\n",string.rep("─",longest_word + 2),string.rep("─",longest_word + 2))
  io.write(header)
  for i = 1, line_ctr-1 do
    io.write(string.format("│ %s │ %s │\n",variable_padding(vocs[i][0],longest_word),variable_padding(vocs[i][1],longest_word)))    
  end
  io.write(bottom)
  
end
-- Scorekeeping 
function sorted_iterator(unsorted_table, order_function) 
  local keys,index = {},0
  for key in pairs(unsorted_table) do 
    keys[#keys+1] = key
  end
  
  if order_function then
    table.sort(keys, function(a,b) return order_function(unsorted_table,a,b) end)
  else 
    table.sort(keys)
  end
  
  return function()
    index = index + 1
    if keys[index] then
      return keys[index],unsorted_table[keys[index]]
    end
  end
end
function score_check(practise_score)
  local score_file = io.input(folder_name .. "Score.txt")
  local file_content = ""
  local best_score = 0.0
  local scores = {0.0,0.0,0.0}
  local if_new = true
  
  for line in score_file:lines() do
    if(line:match(file_name)) then
      if_new = false
      scores[1],scores[2],scores[3] = line:match("(%d+.%d+) : (%d+.%d+) : (%d+.%d+)")
      scores[practise_mode] = (practise_score>tonumber(scores[practise_mode])) and practise_score or scores[practise_mode]
      best_score = scores[practise_mode]
      file_content = file_content .. string.format("%s : %3.2f : %3.2f : %3.2f\n",file_name,scores[1],scores[2],scores[3])
    else 
      file_content = file_content .. line .. "\n"
    end
  end
  
  if if_new then
    best_score = score
    scores[practise_mode] = score
    file_content = file_content .. string.format("%s : %3.2f : %3.2f : %3.2f\n",file_name,scores[1],scores[2],scores[3])
  end
  
  score_file:close()
  score_file = io.open(folder_name .. "Score.txt", "w+") -- override file with updated scores
  score_file:write(file_content)
  score_file:close()
  
  return best_score
end


-- functions to color text in terminal
function color_score(score_value) -- colos[val] + string + \27[0m => colored string
  local colors = {"\27[31m","\27[1;31m","\27[1;33m","\27[32m","\27[1;32m","\27[34m"}
  
  return colors[int_divide(tonumber(score_value),20)+1]
  -- return string.format("%s%3.2f\27[0m",colos[int_divide(tonumber(score_value),20)+1],tonumber(score_value))
  -- ^ will not work with string padding(eg. string.format("%10s",s)), color_padding is the workaround for that
end
function variable_padding(org_string,max_len)
  if(utf8.len(org_string) < max_len) then -- #org_string and string.len wont work with certain chars(eg. äö êé etc.) due to counting bytes not chars
    return org_string .. string.rep(" ",(max_len-utf8.len(org_string))) 
  end
  return org_string
end
function color_padding(org_float) -- will rework this later but works for now
  return color_score(org_float) .. variable_padding(org_float .. "%",8) .. "\27[0m"
end


-- handling launch parameters
function check_arguments(...) 
  arg = {...}
  for _,value in pairs(arg) do
    parse_argument(value)
  end
end
function parse_argument(argument)
  if(argument:find("folder")) then -- mayby to lookup table
    folder_name = get_best_match("folder",argument:match("=(.+)"),"")
  elseif(argument:find("file")) then
    argument = (string.sub(argument,6)) .. ","
    parse_lists(argument:gmatch("[^,]+"))
  elseif(argument:find("mode")) then 
    practise_mode = tonumber(argument:match("%d"))
  elseif(argument:find("audio")) then
    audio_mode = true
  elseif(argument:find("speed")) then
    audio_speed = argument:match("=(%a+)")
  else
    io.write("Unknown Argument:\"".. argument .."\"\n")
  end
end
function parse_lists(iterator) 
  local index = 1
  if iterator ~= nil then
    for value in iterator do
      if value == "all" then --  !!!MAY CAUSE ERROR!!!
        clear_table(file_list)
        select_table()
        return
      end
      file_list[index] = get_best_match("file",value,folder_name)
      print(file_list[index])
      index = index + 1
    end
    next_file_from_list()
  end
end

function next_file_from_list()
 file_name = file_list[1]
  for k,_ in ipairs(file_list) do
    file_list[k] = (file_list[k+1]==nil) and "" or file_list[k+1]
  end
  --return file_name
end


-- small helper functions
function parse_new_vocs(input_str)
  local i = input_str:find("  ")
  if(i ~= nil) then
    return string.format("%s,%s\n",input_str:sub(1,i-1),input_str:sub(i+2,utf8.len(input_str)))
  else  
    i = input_str:find(" ")
    return i == nil and input_str or (string.format("%s,%s",input_str:sub(1,i-1),input_str:sub(i+1,utf8.len(input_str))))
  end
end
function reset_globals()
  file_list = {}
  folder_name,file_name = "",""
  practise_mode = 0
  audio_mode = false
  audio_speed = "medium"
end
function choose_option(content,message) -- get command &| list options and returns choosen answer
  -- content is either a command to get the options or a table containing the options
  io.write(message)
  
  local options,index = {},1
  if type(content) == "string" then
    local tmp_file = assert(io.popen(content))
    for line in tmp_file:lines() do
      if line ~= "Score" then
        options[index] = line
        io.write(string.format("\t[%d] %s\n",index,line))
        index = index + 1
      end
    end
    tmp_file:close()
  else 
  for k,v in ipairs(content) do
    options[k] = v
    io.write(string.format("\t[%d] %s\n",k,v))
    end
  end
  local answer = io.read()
  
  io.write("\n")
  --
  local num, lett = answer:match("(%d*)(i?)")
  --  select_folder()
  --end
  --
  if(options[answer] == nil) then
    for k,v in ipairs(options) do
      if(v:match(answer)) then --  or k:match(answer)
        if(type(content) ~= "string") then
          return 
        end
        return options[k]
      end
    end
  end
  return options[tonumber(answer)]
end
function get_best_match(option,to_match,given_folder)
  local tmp_folder = ""
  local list_of_folder = assert(io.popen("ls -d */"))
  if option == "folder"  then
    for folder in list_of_folder:lines() do
      if(folder:match(to_match) or to_match == '*') then
        list_of_folder:close()
        return folder
    end
  end
  elseif option == "file" then
    if given_folder ~="" then
      local list_of_files = assert(io.popen("ls " .. given_folder .. " -tr | sed s'/.txt//'"))
      for file in list_of_files:lines() do
          if(file:match(to_match) or to_match == '*') then
              list_of_folder:close()
              list_of_files:close()
              return file
          end
        end
    else
      for folder in list_of_folder:lines() do
        local list_of_files = assert(io.popen("ls " .. folder .. " -tr | sed s'/.txt//'"))
        for file in list_of_files:lines() do
          if(file:match(to_match) or to_match == '*') then
              list_of_folder:close()
              list_of_files:close()
            return file
          end
        end
      end
    end
  end
end
function get_hamming_distance(s1,s2)
  local diff = 0
  local len_s1, len_s2 = utf8.len(s1), utf8.len(s2)
  local length = math.min(len_s1,len_s2)
  for index = 0, length do
    diff = s1:sub(index,index) == s2:sub(index,index) and diff or diff + 1
  end
  return diff + math.abs(len_s1 - len_s2)
end
function int_divide(a,b)
  return (a-a%b)/b
end
function is_nil(a)
  return (a == nil or a == "") and false or true
end
function avg(nums_in_string)
  n1,n2,n3 = nums_in_string:match("(%d+.%d+) : (%d+.%d+) : (%d+.%d+)")
  return (n1 + n2 + n3)/3
end
function shuffle_array(array,array_len) -- Fisher-Yates-Shuffle
  for index = array_len-1,2,-1 do
    local random_index = math.random(index)
    array[index],array[random_index] = array[random_index],array[index]
  end
end
function trim(s) -- removes leading/trailing whitespace
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end
function parsed(s) -- mayby later
  pars = ""
  for word in s:gmatch(",?(%a+),?") do  -- [^,]*
    --print(word)
    if trim(word) ~= nil then
    --  pars = pars .. ":" .. trim(word)
      print(trim(word) .. ";END")
    end
  end
end
function select_folder() -- adds complete folder to file_list
  folder_name = folder_name~="" and folder_name or choose_option("ls -d */", "Choose folder:\n")
  local list_of_files = assert(io.popen("ls " .. folder_name .. " -tr | sed s'/.txt//'"))
  parse_lists(list_of_files:lines()) 
end
function clear_table(table)
  for k,_ in ipairs(table) do
    table[k] = nil
  end
end
-- main part

file_list = {}
folder_name,file_name = "",""
practise_mode = 0
audio_mode = false
audio_speed = "medium" -- slow/fast
infinite_practise = false


--select_folder()

check_arguments(...)
setup()


--TODO LATER
function read_file_to_audio(f_name) -- not really working as intended
  local intro = "Now reading " .. f_name
  os.execute("espeak -ven \""..intro.."\"")
  sleep(2)
  local arr = {}
  f = io.input(folder_path..f_name..".txt")
  local line_ctr = 1
  local word_ctr = 1
  local num_correct = 0
  for line in f:lines() do
    arr[line_ctr] = {}
    for i in line:gmatch("[^,?]*") do
      arr[line_ctr][word_ctr] = i
      word_ctr = word_ctr + 1
    end
    word_ctr = 1
    line_ctr = line_ctr + 1
  end
  f:close()
  shuffle_array(arr,line_ctr)
  for a = 1,line_ctr-1,1 do
    os.execute(string.format("espeak -s 100 -vde+f1 \"%s bedeuted \"",arr[a][1]))
    os.execute(string.format("espeak -s 100 -vfr+f1 \"%s\"",arr[a][2]))
    sleep(2)
  end
end
function sleep(n) 
  local t0 = os.clock()
  while os.clock() - t0 <= n do end
end
function clear_score()
  
end
-- TODO LATER END

-- not of any use for now
function set_defaults() -- TODO
  -- default is the first file in the first folder(sorted alphabetically)
  local ret = assert(io.popen("ls -d */ | head -1"))
  local r = string.gsub(ret:read("*a"),"\n","")
  ret:close()
  folder_name = r
  ret = assert(io.popen(string.format("ls %s | head -2",folder_name)))
  r = ret:read()
  file_name = r == "Score.txt" and ret:read() or r
  ret:close()
end
function create_folder()
  io.write("Name new Folder for Vocs: ")
  folder_name = io.read()
  os.execute("mkdir " .. folder_name)
  os.execute("touch " .. folder_name .. "/Score.txt")
end
-- END
