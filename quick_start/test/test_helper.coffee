root = global ? window
root.chai = require('chai')
root.should = chai.should()
root.mock = require("TinyMockJS").mock

# The system under test.
root.Chat = require("../src/Chat").Chat
