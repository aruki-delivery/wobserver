import {Popup} from './popup.js';

class NodeDialog {
  constructor(wobserver) {
    this.wobserver = wobserver;
  }

  show() {
    this.Wobserver2.client.command_promise('nodes')
    .then(e => {
      let nodes = e.data;

      Popup.show(`
      <div id="node_selection">
        <span>Select node:</span>
        <ul id="node_options">
        </ul>
      </div>
      `);

      let node_options = document.getElementById('node_options');

      nodes.forEach((node) => {
        let li = document.createElement('li');
        let selected = (this.Wobserver2.client.node == node.name);

        li.className = selected ? 'node selected' : 'node';

        let local_class = node['local?'] ? ' (local)' : '';

        li.innerHTML = `<span>${node.name}${local_class}</span><detail>${node.host}:${node.port}</detail>`

        if( selected ) {
          li.addEventListener('click', () => this.hide());
        } else {
          li.addEventListener('click', () =>{
            this.Wobserver2.client.set_node(node.name);
            this.hide();
          });
        }

        node_options.appendChild(li);
      });
    });
  }

  hide() {
    Popup.hide();
  }
}

export{ NodeDialog }