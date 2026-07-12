# Serve attachments through Rails so browsers and CDNs can cache the permanent,
# signed Active Storage URLs instead of following a private, non-cacheable redirect.
Rails.application.config.active_storage.resolve_model_to_route = :rails_storage_proxy
