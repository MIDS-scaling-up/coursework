require 'torch'
require 'nn'
require 'LanguageModel'

local cmd = torch.CmdLine()
cmd:option('-checkpoint', 'checkpoints/scifi-model.t7') -- http://from.robinsloan.com/rnn-writer/scifi-model.zip
cmd:option('-word_limit_short', 3)
cmd:option('-word_limit_long', 20)
cmd:option('-port', 8080)
cmd:option('-gpu', 0)
cmd:option('-gpu_backend', 'cuda')
local opt = cmd:parse(arg)

local checkpoint = torch.load(opt.checkpoint)
local model = checkpoint.model

local msg
if opt.gpu >= 0 and opt.gpu_backend == 'cuda' then
  require 'cutorch'
  require 'cunn'
  cutorch.setDevice(opt.gpu + 1)
  model:cuda()
  print(string.format('Running with CUDA on GPU %d', opt.gpu))
elseif opt.gpu >= 0 and opt.gpu_backend == 'opencl' then
  require 'cltorch'
  require 'clnn'
  model:cl()
  print(string.format('Running with OPENCL on GPU %d', opt.gpu))
else
  print('Running in CPU mode... it will be slow!')
end

model:evaluate()

-- utility

-- http://lua-users.org/wiki/StringRecipes
function url_decode(str)
  str = string.gsub(str, '+', ' ')
  str = string.gsub(str, '%%(%x%x)', function(h) return string.char(tonumber(h,16)) end)
  str = string.gsub(str, '\r\n', '\n')
  return str
end

-- let's do this

local app = require('waffle') -- wish i knew how to suppress the graphicsmagick error message… oh well

app.set('host', '0.0.0.0')
app.set('port', opt.port)
app.set('debug', true)

app.get('/', function(req, res)
  res.json{message='Have fun!'}
end)

app.get('/generate', function(req, res)
  local original_start_text = req.url.args.start_text
  local processed_start_text = ''
  if original_start_text ~= nil then -- lua's 'not equals' is weird
    processed_start_text = url_decode(original_start_text:lower()):gsub("%s+"," ")
  end

  local target_num = tonumber(req.url.args.n)
  if target_num == nil then target_num = 1 end
  target_num = math.min(target_num, 10)

  local skip_num = 0
  local t0 = os.clock()

  local generated = {}

  while #generated < target_num do
    local sentence = model:sample(processed_start_text, '[!?\\.]', 3)
    local num_words = 0
    for word in (sentence..' '):gmatch('(.-) ') do num_words = num_words + 1 end -- a bit of a mess
    if (num_words >= opt.word_limit_short) and (num_words <= opt.word_limit_long) then
      table.insert(generated, sentence)
    else
      skip_num = skip_num + 1
    end
  end

  local elapsed = string.format('%.2f', os.clock() - t0)

  print('Generated ' .. #generated .. ' sentences from start text:')
  print('  ' .. processed_start_text)
  print('Skipped ' .. skip_num .. ' sentences')
  print('Took ' .. elapsed .. ' of some undetermined unit of time')

  res.setHeader('Access-Control-Allow-Origin', '*')
--   res.json{start_text=original_start_text, completions=generated, time=elapsed}
  res.json(generated)
end)

app.listen()
