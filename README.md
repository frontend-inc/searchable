# Searchable

A Ruby gem that provides a clean DSL for parsing URL query parameters and applying filters, sorting, and pagination to ActiveRecord models.

## Installation

Add to your Gemfile:

```ruby
gem 'searchable'
```

## Usage

Include the concern in your controller:

```ruby
class ArticlesController < ApplicationController
  include Searchable::Concern

  def index
    @articles = searchable(Article.all)
  end
end
```

### Query Parameters

| Parameter | Example | Description |
|-----------|---------|-------------|
| `filters` | `status:eq:published,views:gt:100` | Filter records |
| `order` | `created_at:desc` | Sort results |
| `page` | `2` | Page number |
| `per_page` | `25` | Results per page |
| `include` | `author,comments` | Eager load associations |
| `keywords` | `ruby rails` | Full-text search (requires `pg_search` or `search` scope) |

### Filter Operators

- `eq` / `neq` - equals / not equals
- `gt` / `gte` - greater than / greater than or equal
- `lt` / `lte` - less than / less than or equal
- `in` / `nin` - in array / not in array
- `btw` - between two values

### Dynamic Values

Filters support dynamic date values: `_1_day_ago`, `_7_days_ago`, `_30_days_ago`, `_current_time`, etc.

```
/articles?filters=created_at:gte:_7_days_ago
```

## License

MIT
