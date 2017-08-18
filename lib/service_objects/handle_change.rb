module ServiceObjects
  class HandleChange < Base
    def call
      actions = []

      begin
        unless SyncADAccount.ignore?(change)
          Log.info "Syncing AD account for person #{change.person_uuid}"
          sync_ad_account = SyncADAccount.new(change)
          actions << sync_ad_account.call
        end

        action = actions.first || :skip
        Log.info "No changes needed for person #{change.person_uuid}" if actions.empty?
        Workers::ChangeFinish.perform_async change.sync_log_id, action

      rescue StandardError => err
        Workers::ChangeError.perform_async change.sync_log_id, err.message
        Raven.capture_exception(err) if defined? Raven
        raise err
      end
    end

    def ignore?
      SyncADAccount.ignore?(change)
    end

    private

    def change_syncs
      Trogdir::APIClient::ChangeSyncs.new
    end
  end
end
