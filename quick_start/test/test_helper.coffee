root = global ? window
root.chai = require('chai')
root.should = chai.should()

{mock} = require("TinyMockJS")
root.mock = mock

{Chat} = require("../src/Chat")
root.Chat = Chat
