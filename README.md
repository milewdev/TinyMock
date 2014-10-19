<!-- build status badge -->
[![Build Status](https://travis-ci.org/milewdev/TinyMock.svg?branch=master)](https://travis-ci.org/milewdev/TinyMock)


### What is TinyMock?
A very small coffeescript mocking framework.


### Documentation
[Here](http://milewdev.github.io/TinyMock.doc/) (documentation source is [here](https://github.com/milewdev/TinyMock.doc)).


### Development Setup

#####Requirements:
- [OS X](https://www.apple.com/osx/)
- [VMware Fusion](http://www.vmware.com/ca/en/products/fusion)
- [Vagrant](http://www.vagrantup.com)
- [Vagrant VMware provider](https://www.vagrantup.com/vmware)
- An OS X Vagrant box named OSX109 (you can use a different name by changing the BOX variable near the top of the Vagrantfile downloaded in the Install step below)

#####Install:
In a terminal window on the host machine:
```
$ mkdir -p ~/work/TinyMock
$ cd ~/work/TinyMock
$ curl -fsSL https://raw.github.com/milewdev/TinyMock/master/Vagrantfile -o Vagrantfile
$ vagrant up --provider=vmware_fusion
...
```

#####Check installation:
In a terminal window on the vm (guest machine):
```
$ cd ~/Documents/TinyMock
$ ./_test
--------------------------------------------------------------------------------

> TinyMock@0.4.0 test /Users/vagrant/Documents/TinyMock
> cake test



  assumptions
    class Object
      ✓ does not have the property or method 'expects' 
      ✓ does not have the property or method 'my_expects' 
...

    ✓ throws an error if the same method throws the same values 
    ✓ throws an error if the same method throws different values 


  101 passing (52ms)
  1 pending
```

#####Uninstall:
**WARNING**: This will completely destroy the vm so you likely want to ensure that you have 
pushed any and all code changes to GitHub beforehand.

In a terminal window on the host machine:
```
$ cd ~/work/TinyMock
$ vagrant destroy -f
$ cd ~
$ rm -r ~/work/TinyMock    # and possibly rm -r ~/work if it is now empty
```


#####Development Notes:
- ./_test will run all business/unit tests.  Leave a terminal window open during development and
run ./_test as you make changes to code.

- ./_build will create TinyMock-0.4.0.tgz.  This file is checked into GitHub so that TinyMock
can be installed using something similar to:
    ```
	$ npm install https://github.com/milewdev/TinyMock/raw/master/TinyMock-0.4.0.tgz
	```
  
- ./_lint will run various checks against the source code, typically looking for things that cropped
up in the TODO list, such as a change in naming convention; in this case, the checks will ensure that 
the old names are not used anywhere.  Warning: the checks are not sophisticated and may report things
that are in fact not erroneous.

- If you wish to modify the Vagrantfile, it is best to do so on the host machine (~/work/TinyMock/Vagrantfile) 
so that you can easily do an edit/vagrant up/vagrant destroy cycle.  Once you have finished making 
changes, vagrant up and then in a terminal window on the vm do something like:
    ```
    $ cd ~/Documents/TinyMock
    $ cp /vagrant/Vagrantfile .
    $ git status
    ...
    $ git add Vagrantfile
    $ git commit -S -m "Insert description of change to Vagrantfile here."
    ...
    $ git push
    ...
    ```


### Thanks
- [Apple](http://www.apple.com)
- [CoffeeScript](http://coffeescript.org)
- [GitHub](https://github.com) and [GitHub pages](http://pages.github.com)
- [mocha](http://visionmedia.github.io/mocha) and [chai](http://chaijs.com)
- [Node.js](http://nodejs.org)
- [npm](https://www.npmjs.org)
- [TextMate](http://macromates.com)
- [Vagrant](https://www.vagrantup.com)
- [VMware](http://www.vmware.com)
