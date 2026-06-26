import React from "react";
import PropTypes from "prop-types";

export default function EventPosterCard({
  eventId,
  title,
  posterUrl,
  dateTimeLabel,
  priceLabel,
  onBuy,
  onTeaser,
}) {
  return (
    <article
      className="event-poster-card"
      data-test="event-poster"
      aria-label={`${title} poster`}
    >
      <div className="poster-media">
        <img
          src={posterUrl}
          alt={`${title} poster`}
          className="poster-img"
          onError={(e) => {
            e.currentTarget.src = "/assets/fallback-poster.jpg";
          }}
        />
      </div>
      <div className="poster-meta">
        <h3 className="poster-title">{title}</h3>
        <div className="poster-sub">{dateTimeLabel}</div>
        <div className="poster-actions">
          <button
            id={`buy-${eventId}`}
            className="btn btn-primary buy-cta"
            onClick={onBuy}
          >
            Buy Livestream Ticket • {priceLabel}
          </button>
          <button
            id={`teaser-${eventId}`}
            className="btn btn-outline"
            onClick={onTeaser}
          >
            Teaser
          </button>
        </div>
      </div>
    </article>
  );
}

EventPosterCard.propTypes = {
  eventId: PropTypes.string.isRequired,
  title: PropTypes.string.isRequired,
  posterUrl: PropTypes.string.isRequired,
  dateTimeLabel: PropTypes.string.isRequired,
  priceLabel: PropTypes.string.isRequired,
  onBuy: PropTypes.func.isRequired,
  onTeaser: PropTypes.func.isRequired,
};
