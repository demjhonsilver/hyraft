<p align="center">
<img src="https://raw.githubusercontent.com/demjhonsilver/hyraft/main/img/logo.png" alt="Logo" width="70" height="70"/>
</p>
<div align="center">

# Hyraft 

[![Gem Version](https://badge.fury.io/rb/hyraft.svg?icon=si%3Arubygems&icon_color=%23ffffff)](https://badge.fury.io/rb/hyraft)
![Downloads](https://img.shields.io/gem/dt/hyraft)
![License](https://img.shields.io/github/license/demjhonsilver/hyraft)
![Ruby Version](https://img.shields.io/badge/ruby-%3E%3D%203.4.0-red)
![Tests](https://github.com/demjhonsilver/hyraft/actions/workflows/ci.yml/badge.svg)


</div>


**A high-performance Ruby web framework with hexagonal architecture**

Hyraft is a modern Ruby web framework that combines excellent performance with clean hexagonal architecture. Built for developers who want both speed and maintainability in their web applications.


## Features

-  **High Performance**: 37-55ms page renders, faster than most Ruby frameworks
-  **Hexagonal Architecture**: Clean separation with ports, adapters, and use cases
-  **Custom Template Engine**: `.hyr` files with metadata, displayers, transmuters, and manifestors
-  **Multi-App Support**: Run multiple applications under one framework
-  **Dual Server Mode**: Web server (port 1091) + API server (port 1092) simultaneously
-  **Auto-Discovery**: Automatic template and component discovery across apps
-  **Lightweight**: Minimal dependencies, maximum performance


## Hyraft Components

-  **Hyraft** - Framework`(Main)`
-  **Hyraft-server** - Server `(Switch Server)`
-  **Hyraft-rule** - CLI `(Commands)`


## Installation

Install the gem and add to your application's Gemfile:

```bash
gem install hyraft
```

## Create a new Hyraft application:

```bash
hyraft do myapp

cd myapp

bundle install && npm install
```
Run server:

```bash

hyraft-server thin

or 

hyr s thin
```

Visit:

```bash
http://localhost:1091
```

## Project Structure

```bash
myapp/
├── adapter-intake/              # Input adapters
│   ├── multi-app/ 
│   ├── admin-app/
│   ├── api-app/
│   │   └── request/             # API controllers/adapters
│   │       └──  articles_api_adapter.rb
│   └── web-app/
│       ├── request/             # Web controllers/adapters
│       │   ├── home_web_adapter.rb
│       │   └── articles_web_adapter.rb
│       │   
│       └── display/             # Hyraft templates (.hyr files)
│           └── pages/
│               ├── home/
│               │   └── home.hyr
│               └── articles/
│                 ├── index.hyr
│                 ├── show.hyr
│                 ├── new.hyr
│                 └── edit.hyr             
│
├── adapter-exhaust/             # Output adapters  
│   └── data-gateway/            # Database access implementations
│       └── sequel_articles_gateway.rb
│
├── engine/                      # Business logic (framework-independent)
│   ├── source/                  # Domain entities
│   │   └── article.rb
│   │
│   ├── circuit/                 # Use cases/business processes
│   │   └── articles_circuit.rb
│   │
│   └── port/                    # Interfaces (abstract)
│       └── articles_gateway_port.rb
│
├── framework/                       # Framework tools
│   ├── adapters/
│   ├── compiler/
│   ├── errors/
│   └── middleware/
│      
├── shared/                       # Shared files
│   └── helpers/
│       ├── pagination_helper.rb
│       └── response_formatter.rb
│
├── infra/                       # Infrastructure
│   ├── config/
│   │   ├── routes/            # Route definitions
│   │   │    ├── api_routes.rb    # API 
│   │   │    └── web_routes.rb    # Web
│   │   │
│   │   ├── environment.rb
│   │   └── error_config.rb
│   │   
│   ├── database/
│   │   ├── migrations/          # Database schema
│   │   │   ├── 001_create_articles.rb
│   │   │   └── 002_add_image_to_articles.rb
│   │   │
│   │   └── sequel_connection.rb # Database configuration
│   │   
│   ├── gems/                  # Third party gems to import
│   │   ├── database.rb        # Database gems
│   │   ├── load_all.rb        # Load all gems
│   │   ├── utilities.rb       # Utilities
│   │   └── web.rb             # Web gems
│   │ 
│   └── server/
│       ├── api-server.ru        # Rack api configuration
│       └── web-server.ru        # Rack web configuration
│         
├── public/                      # Static assets
│    ├── uploads/                 # File uploads (images, etc.)
│    ├── icons/
│    ├── styles/
│    │   └── css/
│    │       ├── main.css
│    │       └── spa.css
│    ├── images/
│    │   ├── hyr-logo.png
│    │   └── hyr-logo.webp
│    ├── favicon.ico
│    │
│    └── index.html
│
├── boot.rb
├── env.yml
├── Gemfile
└── package.json


```

## # For template files ( .hyr )


## VS Code Extension
Enhanced development experience with Hyraft extension for VS Code.

Install from VS Code:

```bash
# Open VS Code then press (ctrl + shift + x)
# Search for "Hyraft"
# Click Install
```

## VS Code Extension ( snippets ) 

Prefix:

Type 3 letters: hyr


It will display the following snippet options:

----------

- hyr-component
- hyr-embed
- hyr-html-method
- hyr-interp
- hyr-template

----------

* In a VS Code extension, snippets are predefined pieces of code or text that can be inserted quickly using a trigger (a prefix) in the editor.


## Official site

Visit: [https://hyraft.com](https://hyraft.com)



## Development

After checking out the repo, run `bundle install` to install dependencies.

Then, run `rake test` to run the tests.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/demjhonsilver/hyraft. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/demjhonsilver/hyraft/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Hyraft project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/demjhonsilver/hyraft/blob/master/CODE_OF_CONDUCT.md).
