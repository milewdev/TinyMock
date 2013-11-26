root = global ? window
root.should = require('chai').should()
root.mock = require("TinyMockJS").mock

# The system under test.
root.Chat = require("../src/Chat").Chat
