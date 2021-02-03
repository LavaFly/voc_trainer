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
   mode=1,2,3
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
  
]]--
-- 
math.randomseed(os.time())
math.random()
math.random()

-- main functions
function setup() -- not pretty, but works for now
  io.write(string.format("Choose Option:\n\t[1]Practise\n\t[2]Add Vocs\n\t[3]Show Scores\n\t[4]Show all Lessons\n"))
  local answ = tonumber(io.read())
  
  if answ == 1 then -- this is so ugly, but a lookup table wont work
    folder_name = folder_name~="" and folder_name or choose_option("ls -d */", "Choose folder:\n")
    file_name = file_name~="" and file_name or choose_option("ls " .. folder_name .. " -tr | sed s'/.txt//'", "\nChoose file:\n")
    file_list[1] = file_name
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
  else
    io.write("idk what to do")
  end
end
function practise()
  for _=0,#file_list-1 do
    
    io.write(string.format("\nNow testing : %s\n",file_name))
    
    if practise_mode == 3 then 
      comp_practise()
      return
    end
  
    local vocs = {}
    local voc_file = io.input(folder_name .. file_name .. ".txt")
    local line_ctr,word_ctr,num_correct,result = 1,1,0,0
  
    for line in voc_file:lines() do
      vocs[line_ctr] = {}
      for i in line:gmatch("[^,?]*") do
        vocs[line_ctr][word_ctr] = i
        word_ctr = word_ctr + 1
      end
      word_ctr = 1
      line_ctr = line_ctr + 1
    end
  
    voc_file:close()
    shuffle_array(vocs,line_ctr)
  
    for a = 1,line_ctr - 1,1 do
      io.write((practise_mode == 1 and (vocs[a][1] .. " in french: ") or (vocs[a][2] .. " in german: ")))
      if io.stdin:read() == (practise_mode == 1 and (vocs[a][2]) or (vocs[a][1])) then
        io.write(" ->correct\n")
        num_correct = num_correct + 1
      else
        io.write(" ->false " .. (practise_mode == 1 and (vocs[a][2]) or (vocs[a][1])) .. "\n")
      end
    end
    result = (num_correct / (line_ctr - 1)) * 100
    local best_score = tonumber(score_check(result))
    io.write(string.format("\n%d out of %d were correct(%3.2f%%)\n",num_correct,line_ctr - 1,result))
    io.write(string.format("\nBest Score : %3.2f%%\n",best_score))
    
    next_file_from_list()
  end
end
function comp_practise()
  local vocs = {}
  local voc_file = io.input(folder_path .. file_name .. ".txt")
  local line_ctr,word_ctr,num_correct,result = 1,1,0,0
  local rnd, now = 0,0
  
  for line in voc_file:lines() do
    vocs[line_ctr] = {}
    for i in line:gmatch("[^,?]*") do
      vocs[line_ctr][word_ctr] = i
      word_ctr = word_ctr + 1
    end
    word_ctr = 1
    line_ctr = line_ctr + 1
  end
  
  voc_file:close()
  shuffle_array(vocs, line_ctr)
    
  for a = 1, line_ctr - 1 do
    now = os.time()
    rnd = int_divide(math.random(), 0.5)
    io.write((rnd == 1 and (vocs[a][1] .. " in french: ") or (vocs[a][2] .. " in german: ")))
    
    if (io.stdin:read() == (rnd and vocs[a][2] or vocs[a][1])) then
      if os.difftime(os.time(), now) <= 5 then
        num_correct = num_correct + 1
      end
    end
    
    io.write( "\n" )
  end
  result = (num_correct / (line_ctr - 1)) * 100
  local best_score = tonumber(score_check(result))
  io.write(string.format("\n%d out of %d were correct(%3.2f%%)\n",num_correct,line_ctr - 1,result))
  io.write(string.format("\nBest Score : %3.2f%%\n",best_score))
end
function new_voc()
  io.write("Name File(if existing, will append):")
  file_name = io.read()
  score_check(file_name,0.0,1)
  local buffer = ""
  io.write("Write 'exit' to end\n")
  repeat
    buffer = buffer .. io.stdin:read() .. "\n"
  until(buffer:match("exit"))
  local new_vocs = io.open(folder_name .. file_name .. ".txt", "a+")
  new_vocs:write(buffer:sub(0,#buffer-5)) -- cutting out the "exit"
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
  io.write("Choose mode:\n\t[1]German -> French\n\t[2]French -> German\n\t[3]Hardcore\n")
  return tonumber(io.read())
end
function choose_option(command,message) -- get command,list options and returns choosen answer
  io.write(message)
  
  local tmp_file = assert(io.popen(command))
  local options,index = {},1
  
  for line in tmp_file:lines() do
    if line ~= "Score.txt" then
      options[index] = line
      io.write(string.format("\t[%d] %s\n",index,line))
      index = index + 1
    end
  end
  
  tmp_file:close()
  io.write("\n")
  local answer = io.read() 
  
  if(tonumber(answer) == nil) then
    for key,value in ipairs(options) do
      if(value:match(answer)) then
        return options[key]
      end
    end
  end
  
  return options[tonumber(answer)]
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
    t[practise_mode] = score
    file_content = file_content .. string.format("%s : %3.2f : %3.2f : %3.2f\n",file_name,scores[1],scores[2],scores[3])
  end
  
  score_file:close()
  score_file = io.open("vocs_from_book/Score.txt", "w+") -- override file with updated scores
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
  if(#org_string < max_len) then
    return org_string .. string.rep(" ",(max_len-#org_string))
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
    folder_name = argument:match("=(.+)")
  elseif(argument:find("file")) then
    argument = argument .. ","
    parse_lists(argument:gmatch("(%w+),"))
  elseif(argument:find("mode")) then 
    practise_mode = argument:match("%d")
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
    for v in iterator do
      file_list[index] = v
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
-- main part

file_list = {}
folder_name,file_name = "",""
practise_mode = 0
audio_mode = false
audio_speed = "medium" -- slow/fast


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
  file_name = r == "index.txt" and ret:read() or r
  ret:close()
end
function create_folder()
  io.write("Name new Folder for Vocs: ")
  folder_name = io.read()
  os.execute("mkdir " .. folder_name)
  os.execute("touch " .. folder_name .. "/Score.txt")
end
-- END
