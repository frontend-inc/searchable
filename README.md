# Searchable

A Ruby gem that provides a clean DSL for parsing URL query parameters and applying filters and pagination to ActiveRecord models.

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
| `field=value` | `status=active` | Filter by equality |
| `field:operator=value` | `age:gte=21` | Filter with operator |
| `query` | `hello world` | Full-text search |
| `page` | `2` | Page number |
| `per_page` | `25` | Results per page |

### Filter Examples

```
?status=active
?age:gte=21
?user_id=me
?status:in=active,pending,draft
?created_at:gte=2025-10-18
?query=hello+world
```

### Filter Operators

- `eq` / `neq` - equals / not equals (default: `eq`)
- `gt` / `gte` - greater than / greater than or equal
- `lt` / `lte` - less than / less than or equal
- `in` / `nin` - in array / not in array

### Dynamic Values

Filters support dynamic date values: `1_day_ago`, `7_days_ago`, `30_days_ago`, `current_time`, etc.

```
?created_at:gte=7_days_ago
```

## License

MIT
