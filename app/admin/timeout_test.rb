# rubocop:disable Metrics/BlockLength
ActiveAdmin.register_page 'Timeout Test' do
  menu parent: 'Other Entities', label: 'Timeout Test'

  DURATIONS = [10, 30, 60, 90, 95, 100, 105, 110, 120, 150, 180, 240, 300].freeze
  MAX_SLEEP = 600

  page_action :sleep, method: :get do
    seconds = params[:seconds].to_f.clamp(0, MAX_SLEEP)
    started_at = Time.current
    Kernel.sleep(seconds)

    response.headers['Cache-Control'] = 'no-store, no-cache, must-revalidate'
    render json: {
      requested: seconds,
      actual: (Time.current - started_at).round(3),
      responded_at: Time.current.iso8601(3)
    }
  end

  content do
    button_classes = 'action-item-button'

    panel 'What this does' do
      div class: 'panel_contents' do
        para 'Each button makes a request to the backend that sleeps for the given number of seconds before responding. ' \
             'If an intermediate proxy gives up first you will see its error instead of the JSON response.'
        ul do
          li 'Cloudflare returns a 524 when the origin sends no response bytes in time (default 100s on Free/Pro/Business).'
          li 'A 502/504 usually means the load balancer or reverse proxy timed out, not Cloudflare.'
          li 'A network error with no status usually means the connection was dropped mid-flight.'
          li "Requests hold a Puma thread for the whole sleep, and there are only #{ENV.fetch('RAILS_MAX_THREADS', 3)} per process - " \
             'run one at a time on production.'
        end
      end
    end

    panel 'Run a test' do
      div class: 'panel_contents' do
        div class: 'flex flex-row flex-wrap gap-2 items-center' do
          DURATIONS.each do |seconds|
            text_node button_tag("#{seconds}s", type: 'button', class: button_classes, data: { seconds: seconds })
          end
        end

        div class: 'flex flex-row gap-2 items-center mt-4' do
          label 'Custom', for: 'timeout-test-custom-seconds'
          text_node number_field_tag('custom_seconds', 100, id: 'timeout-test-custom-seconds', min: 0, max: MAX_SLEEP,
                                                            class: 'w-32 rounded-md py-1.5 px-3 text-base outline-1 -outline-offset-1 outline-gray-300')
          text_node button_tag('Run', type: 'button', class: button_classes, id: 'timeout-test-custom-run')
          text_node button_tag('Abort', type: 'button', class: button_classes, id: 'timeout-test-abort', disabled: true)
        end

        div id: 'timeout-test-status', class: 'mt-4 font-mono' do
          'Idle'
        end
      end
    end

    panel 'Results' do
      div class: 'panel_contents' do
        table id: 'timeout-test-results-table' do
          thead do
            tr do
              th 'Started'
              th 'Requested'
              th 'Elapsed'
              th 'Status'
              th 'CF-Ray'
              th 'Outcome'
            end
          end
          tbody id: 'timeout-test-results'
        end
      end
    end

    text_node javascript_tag(<<~JS)
      (function () {
        const endpoint = '#{admin_timeout_test_sleep_path}';
        const statusEl = document.getElementById('timeout-test-status');
        const resultsEl = document.getElementById('timeout-test-results');
        const abortBtn = document.getElementById('timeout-test-abort');
        const buttons = Array.from(document.querySelectorAll('[data-seconds]'));
        const customRun = document.getElementById('timeout-test-custom-run');
        const customInput = document.getElementById('timeout-test-custom-seconds');
        let controller = null;
        let ticker = null;

        function setRunning(running) {
          buttons.forEach((b) => { b.disabled = running; });
          customRun.disabled = running;
          abortBtn.disabled = !running;
        }

        function addRow(startedAt, requested, elapsed, status, ray, outcome) {
          const tr = document.createElement('tr');
          [
            startedAt.toLocaleTimeString(),
            requested + 's',
            elapsed.toFixed(2) + 's',
            status,
            ray || '-',
            outcome
          ].forEach((value) => {
            const td = document.createElement('td');
            td.textContent = value;
            tr.appendChild(td);
          });
          resultsEl.insertBefore(tr, resultsEl.firstChild);
        }

        async function run(seconds) {
          setRunning(true);
          controller = new AbortController();
          const startedAt = new Date();
          const start = performance.now();
          ticker = setInterval(() => {
            statusEl.textContent = 'Waiting for ' + seconds + 's response... ' +
              ((performance.now() - start) / 1000).toFixed(1) + 's elapsed';
          }, 100);

          let status = 'n/a';
          let ray = null;
          let outcome;

          try {
            const url = endpoint + '?seconds=' + encodeURIComponent(seconds) + '&nocache=' + Date.now();
            const response = await fetch(url, { signal: controller.signal, cache: 'no-store' });
            status = response.status;
            ray = response.headers.get('cf-ray');
            const body = await response.text();

            if (response.ok) {
              outcome = 'OK - ' + body;
            } else if (status === 524) {
              outcome = 'Cloudflare 524 - origin did not respond in time';
            } else if (status === 502 || status === 504) {
              outcome = 'Gateway timeout/error from a proxy in front of Rails';
            } else {
              outcome = 'HTTP ' + status + ' - ' + body.slice(0, 200);
            }
          } catch (error) {
            outcome = error.name === 'AbortError' ? 'Aborted in the browser' : 'Connection failed: ' + error.message;
          } finally {
            clearInterval(ticker);
            const elapsed = (performance.now() - start) / 1000;
            addRow(startedAt, seconds, elapsed, status, ray, outcome);
            statusEl.textContent = 'Idle - last run took ' + elapsed.toFixed(2) + 's';
            controller = null;
            setRunning(false);
          }
        }

        buttons.forEach((button) => {
          button.addEventListener('click', () => run(Number(button.dataset.seconds)));
        });
        customRun.addEventListener('click', () => run(Number(customInput.value)));
        abortBtn.addEventListener('click', () => controller && controller.abort());
      })();
    JS
  end
end
# rubocop:enable Metrics/BlockLength
