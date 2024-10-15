# rubydora
![deprecated](https://img.shields.io/badge/deprecated-red)

Rubydora is a low-level Fedora Commons REST API consumer, providing direct
access to REST API methods, as well as a primitive ruby abstraction.

Code:
[![Gem Version](https://badge.fury.io/rb/rubydora.png)](http://badge.fury.io/rb/rubydora)
[![Build Status](https://circleci.com/gh/samvera-deprecated/rubydora.svg?style=svg)](https://circleci.com/gh/samvera-deprecated/rubydora)
[![Coverage Status](https://coveralls.io/repos/github/samvera/rubydora/badge.svg?branch=main)](https://coveralls.io/github/samvera/rubydora?branch=main)

Docs:
[![Contribution Guidelines](http://img.shields.io/badge/CONTRIBUTING-Guidelines-blue.svg)](./CONTRIBUTING.md)
[![Apache 2.0 License](http://img.shields.io/badge/APACHE2-license-blue.svg)](./LICENSE.txt)

Community Support: [![Samvera Community Slack](https://img.shields.io/badge/samvera-slack-blueviolet)](http://slack.samvera.org/)

## Product Owner & Maintenance

`rubydora` was a Core Component of the Samvera Community. Given a decline in available labor required for maintenance, this project no longer meets the requirements necessary to maintain its status as a core component. Following a public request to the community issued requesting labor needed to ensure that these requirements are met, this project has been deprecated. The documentation for what this means can be found [here](http://samvera.github.io/core_components.html#requirements-for-a-core-component).

## Help

The Samvera community is here to help. Please see our [support guide](./SUPPORT.md).

## Installation

```bash
gem install rubydora
```

## Examples

```
> repo = Rubydora.connect :url => 'http://localhost:8983/fedora', :user => 'fedoraAdmin', :password => 'fedoraAdmin'
=> #<Rubydora::Repository:0x101859538 @config={:url=>"http://localhost:8983/fedora", :user=>"fedoraAdmin", :password=>"fedoraAdmin"}>

> obj = repo.find('test:1')
=> #<Rubydora::DigitalObject:0x101977230 @pid="test:1", @repository=#<Rubydora::Repository:0x1019beef0 @config={:user=>"fedoraAdmin", :url=>"http://localhost:8983/fedora", :password=>"fedora"}>>

> obj.new?
=> true

> obj = obj.save
=> #<Rubydora::DigitalObject:0x1017601b8 @pid="test:1", @repository=#<Rubydora::Repository:0x1018e3058 @config={:url=>"http://localhost:8983/fedora", :user=>"fedoraAdmin", :password=>"fedoraAdmin"}, @client=#<RestClient::Resource:0x101882910 @options={:user=>"fedoraAdmin", :password=>"fedoraAdmin"}, @block=nil, @url="http://localhost:8983/fedora">>>

> obj.profile
=> {"objDissIndexViewURL"=>"http://localhost:8983/fedora/get/test:1/fedora-system:3/viewMethodIndex", "objLabel"=>"", "objModels"=>"info:fedora/fedora-system:FedoraObject-3.0", "objCreateDate"=>"2011-04-18T13:34:11.285Z", "objOwnerId"=>"fedoraAdmin", "objState"=>"A", "objItemIndexViewURL"=>"http://localhost:8983/fedora/get/test:1/fedora-system:3/viewItemIndex", "objLastModDate"=>"2011-04-18T13:47:30.110Z"}

> obj.models
=> ["info:fedora/fedora-system:FedoraObject-3.0"]

> obj.models << 'info:fedora/test:cmodel'
=> ["info:fedora/fedora-system:FedoraObject-3.0", "info:fedora/test:cmodel"]

> obj2 = repo.find('test:2')
=> [...]

> obj1.parts << obj2
=> [...]

> obj.datastreams
=> {"DC"=>#<Rubydora::Datastream:0x101860180 @dsid="DC" ...> }

> ds = obj.datastreams['File']
=> #<Rubydora::Datastream:0x1017f26a8 @dsid="File" ...>
> ds.controlGroup = 'R'
=> "R"
> ds.dsLocation = 'http://example.org/index.html'
=> "http://example.org/index.html"
> ds.dsLabel = 'Example redirect datastream'
=> "Example redirect datastream"
> ds.mimeType = 'text/html'
=> "text/html"
> ds.save
=> #<Rubydora::Datastream:0x10177a568 @dsid="File" ...>

> obj.datastreams
=> {"DC"=>#<Rubydora::Datastream:0x101860180 @dsid="DC" ..., "File"=>#<Rubydora::Datastream:0x10177a568 @dsid="File" ...>}

> obj.datastreams["File"].delete
=> true
> obj.datastreams["File"].new?
=> true
```

## Running the Tests

There is a Dockerfile included here to build a container that runs fcrepo3. It
will listen on port 8983, so no additional configuration is required. You can
run the continuous integration suite or the specs directly. An example of
starting the server and running just the specs is included here:

```
docker build -t samvera/fcrepo3:latest .
RUBYDORA_ID=$(docker run -d -p 8983:8983 samvera/fcrepo3:latest)
bundle exec rspec && docker kill $RUBYDORA_ID
```

There are also Rake tasks for building the image and running the suite against
a container:

```
bundle exec rake docker:build
bundle exec rake docker:spec
```

## Contributing to rubydora

*   If you're working on PR for this project, create a feature branch off of `main`.

  This repository follows the [Samvera Community Code of Conduct](https://samvera.atlassian.net/wiki/spaces/samvera/pages/405212316/Code+of+Conduct) and [language recommendations](https://github.com/samvera/maintenance/blob/main/templates/CONTRIBUTING.md#language).  Please ***do not*** create a branch called `master` for this repository or as part of your pull request; the branch will either need to be removed or renamed before it can be considered for inclusion in the code base and history of this repository.
*   Check out the latest main branch to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
*   Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
*   Fork the project
*   Start a feature/bugfix branch
*   Commit and push until you are happy with your contribution
*   Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
*   Please try not to mess with the Rakefile, version, or history. If you want
    to have your own version, or is otherwise necessary, that is fine, but
    please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2011 Chris Beer. See LICENSE.txt for further details.

## Acknowledgments

This software has been developed by and is brought to you by the Samvera community.  Learn more at the [Samvera website](http://samvera.org/).

![Samvera Logo](https://wiki.duraspace.org/download/thumbnails/87459292/samvera-fall-font2-200w.png?version=1&modificationDate=1498550535816&api=v2)

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/samvera/rubydora/.
