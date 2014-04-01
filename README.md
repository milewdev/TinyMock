### What is TinyMockJS?
A very small coffeescript mocking framework.


### Documentation
[Here](http://milewgit.github.io/TinyMockJS.doc/) (documentation source is [here](https://github.com/milewgit/TinyMockJS.doc)).


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
$ mkdir -p ~/work/TinyMockJS
$ cd ~/work/TinyMockJS
$ curl -fsSL https://raw.github.com/milewgit/TinyMockJS/master/Vagrantfile -o Vagrantfile
$ vagrant up --provider=vmware_fusion
...
```

#####Check installation:
In a terminal window on the vm (guest machine):
```
$ cd ~/Documents/TinyMockJS
$ ./_test

> TinyMockJS@0.2.0 test /Users/vagrant/Documents/TinyMockJS
> cake test

  test pre-conditions
    ✓ Object does not have the property or method 'expects' 
    ✓ Object does not have the property or method 'my_expects' 

...

    ✓ throws an error when the same method throws the same values 
    ✓ throws an error when the same method throws different values 

  74 passing (40ms)
  1 pending
```

#####Uninstall:
**WARNING**: This will completely destroy the vm so you likely want to ensure that you have 
pushed any and all code changes to GitHub beforehand.

In a terminal window on the host machine:
```
$ cd ~/work/TinyMockJS
$ vagrant destroy -f
$ cd ~
$ rm -r ~/work/TinyMockJS    # and possibly rm -r ~/work if it is now empty
```


#####Development Notes:
- ./_test will run all business/unit tests.  Leave a terminal window open during development and
run ./_test as you make changes to code.

- ./_build will create TinyMockJS-0.2.0.tgz.  This file is checked into GitHub so that TinyMockJS
can be installed using:
    ```
	$ npm install https://github.com/milewgit/TinyMockJS/raw/v0.2.0/TinyMockJS-0.2.0.tgz
	```
  
- If you wish to modify the Vagrantfile, it is best to do so on the host machine (~/work/TinyMockJS/Vagrantfile) 
so that you can easily do an edit/vagrant up/vagrant destroy cycle.  Once you have finished making 
changes, vagrant up and then in a terminal window on the vm do something like:
    ```
    $ cd ~/Documents/TinyMockJS
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
