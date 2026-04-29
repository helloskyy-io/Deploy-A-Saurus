<main>
	<img src="frame_002.jpg" alt="Logo">	

<p>The purpose of Hello Skyy is To provide a central hub, on decentralized infrastructure, in order to educate, document, and assemble the information, tools, and collaborative development space needed, as we explore an alternative to the control over people that big tech companies employ as a lucrative business model. We want to offer an alternative to big tech, and teach people how to choose freedom and privacy over convenience by exploring web3, blockchain, decentralization, and open source technologies.</p>

<p>learn more at:</p>
<h3><a href="https://web.helloskyy.io">helloskyy.io</a></h3>
<p>join the discord:</p>
<h3><a href="https://discord.io/techdufus">https://discord.io/techdufus</a></h3>

<h1>FluxEdge AI Toolbox.</h1>

<p>FluxEdge AI Toolbox is designed to streamline the configuration of custom container environments on FluxEdge by providing an Ansible framework to automate the installation of required packages, dependencies, and general setups for various AI frameworks and models, with user requirements that go above and beyond the standard configuration offerings in the FluxEdge market place. Our aim is to enable users to rapidly reproduce custom work environments and allow data scientists to focus more on learning AI and less on grappling with complicated technical setups.</p>

<p>The AI toolbox utilizes a bash script to install Ansible. Ansible is a user friendly, open-source "infrastructure as a code/Configuration as Code" tool that uses the YAML programming language. Accessed through FluxEdge's Terminal GUI, it prompts users to specify their desired environment, based on their intended framework or model. Subsequently, it executes a series of Ansible "plays/tasks/roles" to configure the necessary packages and dependencies. We encourage you use our prebuilt options as well as expand on this and or customize it to your individual needs. Most recently we have added rapid deployment of projects, where a sample project can be installed for a given environment. THe sample project can be used to test the functionality of the environment packages and dependancies, and also allow people to "explore" the world of AI even with very little previous experience. </p>

<p>These tools are freely available to the community for both private and public use. Feel free to use this as a framework to improve upon in your own deployment adventures. If you have changes to this framework that you feel would benefit the community as part of the "base" offering, please submit a pull request!</p>

<p>AI Toolbox assumes the following:</p>

<ol>
  <li>you have created a project at FluxEdge</li>
  <li>you are working in the GUI Terminal in the FluxEdge app</li>
  <li>you have chosen the Ubuntu Custom option from the AI menu</li>
</ol>

<p> To run AI Toolbox copy/paste the following commands into the GUI terminal on FluxEdge, then follow the prompts.</p>

<h3>apt install curl -y <h3>
<h3>bash <(curl -s https://raw.githubusercontent.com/helloskyy-io/FluxEdge-AI-Toolbox/main/bash/AI_toolbox.sh)
</h3>

<p> To manually relaunch the Ansible playbook after installation, copy/paste the following commands into the GUI terminal on FluxEdge </p>

<h3>ansible-playbook -i localhost, -c local /FluxEdge_AI_Toolbox/ansible/playbooks/AI_Toolbox.yml</h3>

<p> - Puma <p>

</main>
