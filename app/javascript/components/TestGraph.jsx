import React from "react"

import * as d3 from "d3"
import * as d3force from "d3-force"

export default class TestGraph extends React.Component {

  componentDidMount() {
    var width = 640;
    var height = 480;

    const nodes = [{}, {}, {}, {}, {}, {}];
    console.log(nodes);

    const links = [
      { source: 0, target: 1, distance: 25 },
      { source: 0, target: 2, distance: 50 },
      { source: 0, target: 3, distance: 75 },
      { source: 0, target: 4, distance: 100 },
      { source: 0, target: 5, distance: 125 },
      { source: 1, target: 5, distance: 50 },
    ];

    var svg = d3.select('#graph-container').append('svg')
        .attr('width', width)
        .attr('height', height);

    var linkForce = d3force.forceLink(links)
        .distance(link => link.distance);

    var simulation = d3force.forceSimulation(nodes)
        .force('link', linkForce)
        .force('center', d3force.forceCenter(width/2, height/2))
        .force('charge', d3force.forceManyBody());

    var linkElements = svg.selectAll('.link')
        .data(links)
        .enter().append('line')
        .attr('class', 'link');

    var nodeElements = svg.selectAll('.node')
        .data(nodes)
        .enter().append('circle')
        .attr('class', 'node')
        .attr('r', width/50);

    simulation.on('tick', function() {

      nodeElements
          .attr('cx', function(d) { return d.x; })
          .attr('cy', function(d) { return d.y; });

      linkElements
          .attr('x1', function(d) { return d.source.x; })
          .attr('y1', function(d) { return d.source.y; })
          .attr('x2', function(d) { return d.target.x; })
          .attr('y2', function(d) { return d.target.y; });
    });
  }

  render() {
    return (
        <div id="graph-container">
        </div>
    )
  }
}
