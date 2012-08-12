# Support Helpdesk - Redmine plugin
# Copyright (C) 2012 Paul Van de Vreede
#
# This file is part of Support Helpdesk.
#
# Support Helpdesk is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Support Helpdesk is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Support Helpdesk.  If not, see <http://www.gnu.org/licenses/>.

class JournalHookListener < Redmine::Hook::ViewListener

  def view_issues_edit_notes_bottom(context={})
    # only show email to user if there is a support setup
    begin
      support = context[:issue].support_helpdesk_setting
      return if support == nil
    rescue NoMethodError => e
      return
    end

    # only show email user if available on the issue
    if context[:issue].reply_email != nil and context[:issue].reply_email != ''
      context[:controller].send(:render_to_string, {
        :partial => "issues/email_to_user_option",
        :locals => context
      })
    end
  end

  def controller_issues_edit_before_save(context={})
    issue = context[:issue]

    # code for sending email to user
    if context[:params][:email_to_user]
      # double check that we can email the user
      return unless can_send_item? issue

      notes = context[:journal].notes
      return if notes == ""

      Support.log_info "Emailing note for #{issue.id} to #{issue.reply_email}."
      begin
        mail = SupportHelpdeskMailer.user_question(issue, textilizable(notes), issue.reply_email).deliver
      rescue Exception => e
        Support.log_error "Error in sending email for #{issue.id}: #{e}\n#{e.backtrace.join("\n")}"
        email_status = "Error sending email, email was *NOT* sent:"
      else
        email_status = "Emailed to #{issue.reply_email} at #{Time.now.to_s}:"

        # save the email sent for our records
        SupportMailHandler.attach_email(
            issue,
            mail.encoded,
            "#{mail.from}_#{mail.to}.eml",
            "Email sent to Customer from note."
          )
      end

      # add info to the note so we know it was emailed.
      context[:journal].notes = <<-NOTE
#{email_status} 

#{notes}
NOTE

    end

    if context[:params][:resend_creation_email]
      return unless can_send_item? issue

      begin
        mail = SupportHelpdeskMailer.ticket_created(issue, issue.reply_email).deliver
      rescue Exception => e
        Support.log_error "Error in sending email for #{issue.id}: #{e}\n#{e.backtrace.join("\n")}"
        email_status = "Error sending ticket creation email, email was *NOT* sent."
      else
        email_status = "Emailed ticket creation to #{mail.to} at #{Time.now.to_s}."

        # save the email sent for our records
        SupportMailHandler.attach_email(
            issue,
            mail.encoded,
            "#{mail.from}_#{mail.to}.eml",
            "Ticket created email resent to user."
          )
      end

      # add a note to the issue so we know the closing email was sent
      journal = Journal.new
      journal.notes = email_status
      journal.user_id = issue.support_helpdesk_setting.author_id
      issue.journals << journal
    end

    if context[:params][:resend_closing_email]
      return unless can_send_item? issue

      begin
        mail = SupportHelpdeskMailer.ticket_closed(issue, issue.reply_email).deliver
      rescue Exception => e
        Support.log_error "Error in sending email for #{issue.id}: #{e}\n#{e.backtrace.join("\n")}"
        email_status = "Error sending closing email, email was *NOT* sent."
      else
        email_status = "Closing email to #{mail.to} at #{Time.now.to_s}."

        # save the email sent for our records
        SupportMailHandler.attach_email(
            issue,
            mail.encoded,
            "#{mail.from}_#{mail.to}.eml",
            "Closing email resent to user."
          )
      end

      # add a note to the issue so we know the closing email was sent
      journal = Journal.new
      journal.notes = email_status
      journal.user_id = issue.support_helpdesk_setting.author_id
      issue.journals << journal
    end
  end

  private
  def can_send_item?(issue)
    reply_email = issue.reply_email
    return false if reply_email == nil or reply_email == ""
    return true
  end

end
    