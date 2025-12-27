---
layout: default
title: Support
description: Contact Afterflow support and send feedback.
permalink: /support/
---

<div class="card">
  <p>Send feedback, report a bug, or ask a question. Messages are delivered by Formspree.</p>

  <form
    action="https://formspree.io/f/mbdjgoqw"
    method="POST"
    class="card"
  >
    <!-- Optional subject line -->
    <input type="hidden" name="_subject" value="Afterflow Support Request" />

    <!-- Redirect after submit -->
    <input
      type="hidden"
      name="_next"
      value="{{ '/support?submitted=1' | relative_url }}"
    />

    <!-- Honeypot spam protection -->
    <input
      type="text"
      name="_gotcha"
      style="display:none"
      tabindex="-1"
      autocomplete="off"
    />

    <p>
      Send feedback, report a bug, or ask a question.
      Messages are delivered privately via email.
    </p>

    <label for="email">Your email (optional)</label>
    <input
      id="email"
      name="email"
      type="email"
      placeholder="you@example.com"
    />

    <label for="topic">Topic</label>
    <input
      id="topic"
      name="topic"
      type="text"
      placeholder="Bug report, feature request, question…"
      required
    />

    <label for="message">Message</label>
    <textarea
      id="message"
      name="message"
      placeholder="How can I help?"
      required
    ></textarea>

    <p class="hint">
      Please don’t include sensitive personal or medical information.
    </p>

    <button type="submit" class="primary">
      Send
    </button>
  </form>
</div>

<script>
  const params = new URLSearchParams(window.location.search);
  if (params.get("submitted") === "1") {
    const form = document.querySelector("form");
    if (form) {
      form.innerHTML = `
        <p><strong>Thanks!</strong></p>
        <p>Your message has been sent successfully.</p>
        <p>If you included an email address, I’ll reply there.</p>
      `;
    }
  }
</script>