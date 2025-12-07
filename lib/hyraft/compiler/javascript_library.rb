# lib/hyraft/compiler/javascript_library.rb
require_relative 'javascript_obfuscator'

module Hyraft
  module Compiler
    class JavaScriptLibrary
      # Store the original clean version
      CLEAN_LIBRARIES = {
        'lib/neonpulse' => <<~JAVASCRIPT
        /* NeonPulse Library  */
        (() => {
          'use strict';
          
          class NeonPulse {
            #signals = new Map();
            #outputs = new Map();
            #processors = new Map();
            #forms = new Map();

            constructor() {
              this.#initialize();
            }

            #initialize = () => {
              const readyHandler = () => {
                this.#connectOutputs();
                this.#connectForms();
              };

              document.readyState === 'loading' 
                ? document.addEventListener('DOMContentLoaded', readyHandler)
                : readyHandler();
            };

            #connectOutputs = () => {
              const signalElements = [...document.querySelectorAll('[data-neon]')];
              const actionElements = [...document.querySelectorAll('[data-pulse]')];

              signalElements.forEach(element => {
                const signalName = element.dataset.neon;
                const property = element.dataset.property || 'textContent';
                
                if (!this.#outputs.has(signalName)) {
                  this.#outputs.set(signalName, []);
                }
                this.#outputs.get(signalName).push({ element, property });
                
                const signal = this.#signals.get(signalName);
                signal && this.#updateElement(element, signal.value, property);
              });

              actionElements.forEach(element => {
                const [processor, action] = element.dataset.pulse?.split('.') ?? [];
                const eventType = element.dataset.event || 'click';

                element.addEventListener(eventType, event => {
                  window[processor]?.[action]?.(event);
                });
              });
            };

            #connectForms = () => {
              const formElements = [...document.querySelectorAll('form[data-neon-form]')];

              formElements.forEach(form => {
                const formName = form.dataset.neonForm;
                const [processor, action] = form.dataset.submit?.split('.') ?? [];

                if (processor && action) {
                  form.addEventListener('submit', event => {
                    event.preventDefault();
                    event.stopPropagation();
                    window[processor]?.[action]?.(this.#getFormData(form), event);
                  });

                  this.#forms.set(formName, form);
                }

                this.#bindFormInputs(form);
              });
            };

            #bindFormInputs = form => {
              const inputs = form.querySelectorAll('input, textarea, select');

              inputs.forEach(input => {
                const signalName = input.dataset.neon;
                if (!signalName || !this.#signals.has(signalName)) return;

                const signal = this.#signals.get(signalName);

                // Set initial value from signal
                if (!['checkbox', 'radio'].includes(input.type)) {
                  input.value = signal.value ?? '';
                }

                // Bind input events to update signals
                input.addEventListener('input', () => {
                  if (input.type === 'checkbox') {
                    signal.value = input.checked;
                  } else if (input.type === 'radio') {
                    if (input.checked) signal.value = input.value;
                  } else {
                    signal.value = input.value;
                  }
                });

                // Bind signal changes to update input
                const unwatch = this.watch(signalName, newValue => {
                  if (input.type === 'checkbox') {
                    input.checked = !!newValue;
                  } else if (input.type === 'radio') {
                    input.checked = (input.value === newValue);
                  } else {
                    input.value = newValue ?? '';
                  }
                });

                // Store unwatch function for cleanup
                if (!this.#forms.has('_watchers')) {
                  this.#forms.set('_watchers', new Map());
                }
                this.#forms.get('_watchers').set(input, unwatch);
              });
            };

            #getFormData = form => {
              const formData = {};
              const inputs = form.querySelectorAll('input, textarea, select');

              inputs.forEach(input => {
                const name = input.name || input.id;
                if (!name) return;

                if (input.type === 'checkbox') {
                  formData[name] = input.checked;
                } else if (input.type === 'radio') {
                  if (input.checked) formData[name] = input.value;
                } else if (input.type === 'select-multiple') {
                  formData[name] = [...input.selectedOptions].map(opt => opt.value);
                } else {
                  formData[name] = input.value;
                }
              });

              return formData;
            };

            #emitSignal = signalName => {
              const connectedElements = this.#outputs.get(signalName);
              const signal = this.#signals.get(signalName);
              
              connectedElements?.forEach(({ element, property }) => {
                this.#updateElement(element, signal.value, property);
              });
            };

            #updateElement = (element, value, property) => {
              if (!element) return;
              
              const updates = {
                class: () => element.className = value,
                style: () => element.style.cssText = value,
                value: () => {
                  if (element.tagName === 'INPUT' || element.tagName === 'TEXTAREA') {
                    element.value = value;
                  }
                }
              };

              updates[property]?.() ?? (element[property] = value);
            };

            // Public API
            neon = (signalName, initialValue) => {
              const proxy = new Proxy({ value: initialValue }, {
                set: (target, property, value) => {
                  const success = Reflect.set(target, property, value);
                  if (success && property === 'value') {
                    this.#emitSignal(signalName);
                  }
                  return success;
                }
              });
              
              this.#signals.set(signalName, proxy);
              return proxy;
            };

            pulse = (name, actions) => {
              const boundActions = Object.fromEntries(
                Object.entries(actions).map(([key, value]) => [
                  key,
                  typeof value === 'function' ? value.bind(actions) : value
                ])
              );
              
              window[name] = boundActions;
              return boundActions;
            };

            neonBatch = signalsObj => {
              const results = {};
              Object.keys(signalsObj).forEach(key => {
                results[key] = this.neon(key, signalsObj[key]);
              });
              return results;
            };

            watch = (signalName, callback) => {
              const signal = this.#signals.get(signalName);
              if (!signal) return;
              
              let previousValue = signal.value;
              const watcher = setInterval(() => {
                if (signal.value !== previousValue) {
                  callback(signal.value, previousValue);
                  previousValue = signal.value;
                }
              }, 100);
              
              return () => clearInterval(watcher);
            };

            form = (formName, initialData) => {
              const formData = this.neonBatch(initialData ?? {});
              return formData;
            };

            submit = (formName, handler) => {
              const form = this.#forms.get(formName);
              if (form && handler) {
                form.addEventListener('submit', event => {
                  event.preventDefault();
                  const formData = this.#getFormData(form);
                  handler(formData, event);
                });
              }
            };

            cleanup = () => {
              if (this.#forms.has('_watchers')) {
                this.#forms.get('_watchers').forEach(unwatch => {
                  typeof unwatch === 'function' && unwatch();
                });
              }
            };
          }

          window.neonPulse = new NeonPulse();
          // console.log('🚀 NeonPulse activated);
        })();
        JAVASCRIPT
      }

      def self.get(library_name, obfuscation_method: :multi_layer)
        clean_code = CLEAN_LIBRARIES[library_name]
        return nil unless clean_code
        
        case obfuscation_method
        when :split_and_reassemble
          JavaScriptObfuscator.split_and_reassemble(clean_code)
        when :multi_layer
          JavaScriptObfuscator.multi_layer_obfuscation(clean_code)
        when :none
          clean_code
        else
          JavaScriptObfuscator.multi_layer_obfuscation(clean_code)
        end
      end

      def self.available_libraries
        CLEAN_LIBRARIES.keys
      end
      
      def self.obfuscation_methods
        [:multi_layer, :split_and_reassemble, :none]
      end
    end
  end
end