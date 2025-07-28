# Scalability and Performance Strategies

This document outlines the comprehensive strategies implemented in the Good Night App to ensure optimal performance and scalability as the application grows.

## Application-Level Strategies

### 1. Pagination Strategy
- **Implementation**: Implement pagination to limit data load and improve performance for large datasets
- **Benefits**: 
  - Reduces memory usage on both server and client
  - Improves response times for large result sets
  - Better user experience with faster page loads
- **Usage**: Applied to endpoints that return lists of data (sleep records, summaries, etc.)

### 2. Date Range Limitation
- **Implementation**: Limit queries to relevant date ranges to reduce the volume of data processed and returned
- **Benefits**:
  - Significantly reduces query execution time
  - Minimizes network transfer overhead
  - Focuses on relevant data for user context
- **Usage**: Sleep summaries, sleep records, and following data queries

### 3. Query Optimization
- **Implementation**: Refactor queries to be more efficient—avoid unnecessary joins, select only required fields, and leverage batch loading where possible

### 4. Background Aggregation
- **Implementation**: Perform aggregation tasks asynchronously in the background to prevent blocking the main application thread
- **Benefits**:
  - Non-blocking user experience
  - Better resource utilization
  - Improved application responsiveness
- **Usage**: Daily sleep summary calculations

## Database-Level Strategies

### 1. Indexing and Composite Indexing
Create targeted indexes for the most frequent query patterns:

#### Daily Sleep Summaries
```ruby
# User-specific summaries with duration filtering
add_index :daily_sleep_summaries, [:user_id, :total_sleep_duration_minutes, :date], 
          name: 'index_daily_sleep_summaries_on_user_duration_date'

# Unique constraint for user-date combinations
add_index :daily_sleep_summaries, [:user_id, :date], unique: true

# Date-based queries for summaries
add_index :daily_sleep_summaries, [:date, :user_id]
```

#### Sleep Records
```ruby
# User sleep records with clock-in time
add_index :sleeps, [:user_id, :clock_in_time, :duration_minutes]

# Active sleep sessions (clocked in but not out)
add_index :sleeps, [:user_id], where: "clock_out_time IS NULL"

# Date range queries for sleep records
add_index :sleeps, [:user_id, :clock_in_time]
```

#### Follows
```ruby
# Following relationships
add_index :follows, [:follower_id, :following_id], unique: true

# Reverse lookup for followers
add_index :follows, [:following_id, :follower_id]
```

### 2. Precalculated Aggregations
Move complex calculations from the application layer into the database to avoid:
- On-the-fly computations that consume CPU resources
- High memory usage from large datasets in application memory
- Redundant recalculations of the same data

#### Implementation Examples:
```ruby
# Daily sleep summaries with precalculated totals
class DailySleepSummary < ApplicationRecord
  belongs_to :user
  
  validates :date, presence: true
  validates :total_sleep_duration_minutes, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :number_of_sleep_sessions, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :user_id, uniqueness: { scope: :date, message: "already has a summary for this date" }
end
```

### 3. Aggregation via Query
Perform aggregations directly at the SQL level to avoid N+1 query problems:

#### Examples:
```ruby
user.daily_sleep_summaries
                     .where(date: parsed_start_date..parsed_end_date)
                     .reorder(nil)
                     .pluck(
                       Arel.sql('COUNT(*)'),
                       Arel.sql('COALESCE(SUM(total_sleep_duration_minutes), 0)'),
                       Arel.sql('COALESCE(SUM(number_of_sleep_sessions), 0)'),
                       Arel.sql("COUNT(CASE WHEN total_sleep_duration_minutes > 0 THEN 1 END)")
                     )
                     .first
```