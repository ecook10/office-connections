import React from "react"

import * as d3 from "d3"
import * as d3force from "d3-force"

import GraphDetails from "components/GraphDetails.jsx"

const degreeColorMap = ["red", "blue", "black"];
const degreeRadiusMap = [15, 10, 8];

export default class GraphView extends React.Component {

  constructor(props) {
    super(props);
    this.state = {};
    
    this.nodeClicked = this.nodeClicked.bind(this);
    this.highlightAllPathsToLead = this.highlightAllPathsToLead.bind(this);
  }

  highlightAllPathsToLead(startNodeDatum) {

    if (startNodeDatum.name == this.props.leadNodeName) {
      return [];

    } else {
      var completedPaths = [];
      d3.selectAll('.link')
        .filter(function(d) { return d.target.name == startNodeDatum.name; })
          .attr("stroke-width", 3)
          .attr("stroke", "red")
        .each(function(d) {
          var leadPaths = this.highlightAllPathsToLead(d.source);
          completedPaths.push(leadPaths.map(path => [{ target: d.target, source: d.source}] + path));
        }.bind(this))

      return completedPaths
    }
  }

  nodeClicked() {
    var clickedNode = d3.select(d3.event.target);

    if (this.state.leadNode != clickedNode && this.state.selectedNode != clickedNode) {

      this.state.selectedNode && this.state.selectedNode
          .attr("stroke-width", 0)
          .attr("r", function(d) { return degreeRadiusMap[d.degree]; })

      clickedNode
          .attr("stroke-width", 2)
          .attr("stroke", "red")
          .attr("r", degreeRadiusMap[0])

      d3.selectAll('.link')
          .attr("stroke-width", 1)
          .attr("stroke", "black")

      var pathsToLead = this.highlightAllPathsToLead(clickedNode.datum());
      console.log(pathsToLead);

      this.setState({
        selectedNode: clickedNode,
        selectedNodeName: clickedNode.datum().name,
        pathsToLead: pathsToLead
      });
    }
  }

  componentDidMount() {

    const nodes = this.props.nodes;
    const links = this.props.links;

    var container = d3.select('#' + this.props.id);
    const width = container.node().getBoundingClientRect().width;
    const height = container.node().getBoundingClientRect().height;

    var svg = container.append('svg')
        .attr('width', width)
        .attr('height', height)

    var linkForce = d3force.forceLink(links)
        .distance(link => link.distance)
        .id(node => node.name)

    var simulation = d3force.forceSimulation(nodes)
        .force('link', linkForce)
        .force('collision', d3force.forceCollide(function(d) { return degreeRadiusMap[d.degree] + 5; }))
        .force('center', d3force.forceCenter(width/2, height/2))
        .force('charge', d3force.forceManyBody())

    var linkElements = svg.selectAll('.link')
        .data(links)
        .enter().append('line')
        .attr('class', 'link')
        .attr("stroke-width", 1)
        .attr("stroke", function(d) { return degreeColorMap[d.degree] })

    var nodeElements = svg.selectAll('.node')
        .data(nodes)
        .enter().append('circle')
        .classed("node", true)
        .attr('r', function(d) { return degreeRadiusMap[d.degree]; })
        .attr("fill", function(d) { return degreeColorMap[d.degree] })
        .on('click', this.nodeClicked)

    var leadNodeName = this.props.leadNodeName;
    this.setState({
      leadNode: nodeElements.filter(function(d) { return d.name == leadNodeName })
    });

    simulation.on('tick', function() {

      linkElements
          .attr('x1', function(d) { return d.source.x; })
          .attr('y1', function(d) { return d.source.y; })
          .attr('x2', function(d) { return d.target.x; })
          .attr('y2', function(d) { return d.target.y; })

      nodeElements
          .attr('cx', function(d) { return d.x; })
          .attr('cy', function(d) { return d.y; })
    });
  }

  render() {
    return (
        <div className="graph-view">
          <div className="graph-container" id={ this.props.id }>
          </div>
          <GraphDetails
            leadNodeName={ this.props.leadNodeName }
            leadNodeProjects={ this.props.assignedProjects }
            leadNodeProjectProportions={ this.props.assignedProjectProportions }
            selectedNodeName={ this.state.selectedNodeName } />
        </div>
    )
  }
}
