root = global ? window
root.chai = require('chai')
root.should = chai.should()

{mock} = require("TinyMockJS")
root.mock = mock
